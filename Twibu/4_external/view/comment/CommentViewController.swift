//
//  CommentViewController.swift
//  Twibu
//
//  Created by abeyuya on 2019/06/20.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import UIKit
import FirebaseAuth

final class CommentViewController: UIViewController, StoryboardInstantiatable {

    @IBOutlet weak var tableview: UITableView!

    private let refreshControll = UIRefreshControl()

    var bookmark: Bookmark?
    var comments: [Comment] = []
//    var commentsWithMessage: [Comment] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        setupTableview()
        setupComments()
    }

    private func setupTableview() {
        tableview.tableFooterView = UIView()
        tableview.delegate = self
        tableview.dataSource = self
        tableview.register(
            UINib(nibName: "CommentTableViewCell", bundle: nil),
            forCellReuseIdentifier: "CommentTableViewCell"
        )
        refreshControll.addTarget(self, action: #selector(refresh), for: .valueChanged)
        tableview.refreshControl = refreshControll
    }

    private func setupComments() {
        guard let buid = self.bookmark?.uid else { return }
        refreshControll.beginRefreshing()

        CommentRepository.fetchBookmarkComment(bookmarkUid: buid) { [weak self] result in
            self?.refreshControll.endRefreshing()

            switch result {
            case .failure(let error):
                self?.showAlert(title: "Error", message: error.displayMessage)
            case .success(let comments):
                self?.comments = comments
                self?.tableview.reloadData()
            }
        }
    }

//    private func setupCommentsWithMessage() {
//        let cwm = comments.filter { c in
//
//        }
//    }

    @objc
    private func refresh() {
        guard let b = bookmark else { return }

        guard UserRepository.isTwitterLogin() else {
            setupComments()
            return
        }

        let param = CommentRepository.ExecUpdateBookmarkCommentParam(bookmarkUid: b.uid, url: b.url)
        CommentRepository.execUpdateBookmarkComment(param: param) { [weak self] result in
            switch result {
            case .failure(let error):
                self?.showAlert(title: "Error", message: error.displayMessage)
            case .success(_):
                self?.setupComments()
            }
        }
    }

    @objc
    private func close() {
        dismiss(animated: true)
    }
}

extension CommentViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "CommentTableViewCell") as? CommentTableViewCell else {
            return UITableViewCell()
        }

        let c = comments[indexPath.row]
        cell.set(bookmark: bookmark, comment: c)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let c = comments[indexPath.row]
        guard let url = c.url else { return }
        UIApplication.shared.open(url, options: [:]) { success in
            guard success else {
                print("open error")
                return
            }
        }
    }
}

extension CommentViewController: UITableViewDelegate {}
