//
//  CommentViewController.swift
//  Twibu
//
//  Created by abeyuya on 2019/06/20.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import UIKit
import FirebaseAuth
import ReSwift

final class CommentViewController: UIViewController, StoryboardInstantiatable {

    @IBOutlet weak var tableview: UITableView!

    private let refreshControll = UIRefreshControl()

    var bookmark: Bookmark?
    private var commentsResponse: ResponseState<[Comment]> = .notYetLoading
//    var commentsWithMessage: [Comment] = []

    private var comments: [Comment] {
        switch commentsResponse {
        case .success(let comments): return comments
        case .loading(let comments): return comments
        case .faillure(_): return []
        case .notYetLoading: return []
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupTableview()

        store.subscribe(self) { [weak self] subcription in
            subcription.select { state in
                guard let buid = self?.bookmark?.uid else { return nil }
                return state.response.comments[buid]
            }
        }
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

    private func fetchComments() {
        guard let buid = bookmark?.uid else { return }
        refreshControll.beginRefreshing()
        CommentDispatcher.fetchComments(buid: buid)
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
            fetchComments()
            return
        }

        let param = CommentRepository.ExecUpdateBookmarkCommentParam(bookmarkUid: b.uid, url: b.url)
        CommentRepository.execUpdateBookmarkComment(param: param) { [weak self] result in
            switch result {
            case .failure(let error):
                self?.showAlert(title: "Error", message: error.displayMessage)
            case .success(_):
                self?.fetchComments()
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

extension CommentViewController: StoreSubscriber {
    typealias StoreSubscriberStateType = ResponseState<[Comment]>?

    func newState(state: ResponseState<[Comment]>?) {
        guard let res = state else {
            // 初回取得前はここを通る
            commentsResponse = .notYetLoading
            fetchComments()
            return
        }

        commentsResponse = res

        DispatchQueue.main.async {
            self.render()
        }
    }

    private func render() {
        switch commentsResponse {
        case .success(_):
            refreshControll.endRefreshing()
            tableview.reloadData()
        case .faillure(let error):
            refreshControll.endRefreshing()
            showAlert(title: "Error", message: error.displayMessage)
        case .loading(_):
            refreshControll.beginRefreshing()
        case .notYetLoading:
            refreshControll.endRefreshing()
        }
    }
}
