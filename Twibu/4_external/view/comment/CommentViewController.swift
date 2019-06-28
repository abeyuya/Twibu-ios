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
    private var commentsResponse: Repository.Response<[Comment]> = .notYetLoading
//    var commentsWithMessage: [Comment] = []

    private var comments: [Comment] {
        return commentsResponse.item ?? []
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupTableview()

        store.subscribe(self) { [weak self] subcription in
            subcription.select { state in
                guard let buid = self?.bookmark?.uid else { return nil }
                guard let res = state.response.comments[buid] else { return nil }
                return res
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

    private func fetchComments(type: Repository.FetchType) {
        guard let buid = bookmark?.uid else { return }

        switch commentsResponse {
        case .loading(_):
            return
        case .notYetLoading, .failure(_), .success(_):
            CommentDispatcher.fetchComments(buid: buid, type: type)
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
            fetchComments(type: .new)
            return
        }

        CommentRepository.execUpdateBookmarkComment(bookmarkUid: b.uid, url: b.url) { [weak self] result in
            switch result {
            case .failure(let error):
                self?.showAlert(title: "Error", message: error.displayMessage)
            case .success(_):
                self?.fetchComments(type: .new)
            case .notYetLoading:
                return
            case .loading(_):
                return
            }
        }
    }

    @objc
    private func close() {
        dismiss(animated: true)
    }

    private func startRefreshControll() {
        if refreshControll.isRefreshing {
            return
        }
        refreshControll.beginRefreshing()
    }

    private func endRefreshController() {
        if refreshControll.isRefreshing {
            refreshControll.endRefreshing()
        }
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
        guard let url = c.tweetUrl else { return }
        UIApplication.shared.open(url, options: [:]) { success in
            guard success else {
                print("open error")
                return
            }
        }
    }
}

extension CommentViewController: UITableViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let currentPoint = scrollView.contentOffset
        let contentSize = scrollView.contentSize
        let frameSize = scrollView.frame
        let maxOffSet = contentSize.height - frameSize.height

        // 無限スクロールするためのイベント発火
        let distanceToBottom = maxOffSet - currentPoint.y
        if distanceToBottom < 300 {
//            fetchComments(type: .add)
        }
    }
}

extension CommentViewController: StoreSubscriber {
    typealias StoreSubscriberStateType = Repository.Response<[Comment]>?

    func newState(state: Repository.Response<[Comment]>?) {
        guard let res = state else {
            // 初回取得前はここを通る
            commentsResponse = .notYetLoading
            fetchComments(type: .new)
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
            endRefreshController()
            tableview.reloadData()
        case .failure(let error):
            endRefreshController()
            showAlert(title: "Error", message: error.displayMessage)
        case .loading(_):
            startRefreshControll()
        case .notYetLoading:
            endRefreshController()
        }
    }
}
