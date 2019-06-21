//
//  CommentViewController.swift
//  Twibu
//
//  Created by abeyuya on 2019/06/20.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import UIKit

final class CommentViewController: UIViewController {

    @IBOutlet weak var tableview: UITableView!

    private let refreshControll = UIRefreshControl()

    var bookmark: Bookmark?
    var comments: [Comment] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        setupTableview()
//        setupNavigation()
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

    private func setupNavigation() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(close)
        )
    }

    private func setupComments() {
        guard let buid = self.bookmark?.uid else { return }
        refreshControll.beginRefreshing()

        CommentRepository.fetchBookmarkComment(bookmarkUid: buid) { [weak self] result in
            self?.refreshControll.endRefreshing()

            switch result {
            case .failure(let error):
                self?.showAlert(title: "Error", message: error.localizedDescription)
            case .success(let comments):
                self?.comments = comments
                self?.tableview.reloadData()
            }
        }
    }

    @objc
    private func refresh() {
        guard let buid = self.bookmark?.uid else { return }

        BookmarkRepository.execUpdateBookmarkComment(bookmarkUid: buid) { [weak self] result in
            switch result {
            case .failure(let error):
                self?.showAlert(title: "Error", message: error.localizedDescription)
            case .success(_):
                self?.setupComments()
            }
        }
    }

    @objc
    private func close() {
        dismiss(animated: true)
    }

    private func showAlert(title: String?, message: String) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        let okAction = UIAlertAction(title: "OK", style: .cancel)
        alert.addAction(okAction)
        present(alert, animated: true)
    }
}

extension CommentViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "CommentTableViewCell") as? CommentTableViewCell else {
            return UITableViewCell()
        }

        let c = comments[indexPath.row]
        cell.set(comment: c)
        return cell
    }
}
