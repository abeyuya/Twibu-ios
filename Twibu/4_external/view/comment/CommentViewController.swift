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
    var commentType: CommentRootViewController.CommentType = .left

    private var cellHeight: [IndexPath: CGFloat] = [:]
    private var commentsResponse: Repository.Response<[Comment]> = .notYetLoading
    private var currentUser: TwibuUser?
    private var comments: [Comment] {
        return commentsResponse.item ?? []
    }

    private var currentComments: [Comment] {
        switch commentType {
        case .left:
            return comments.filter { $0.has_comment == true }
        case .right:
            return comments.filter { $0.has_comment == nil || $0.has_comment == false }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupTableview()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        store.subscribe(self) { [weak self] subcription in
            subcription.select { state in
                let res: Repository.Response<[Comment]>? = {
                    guard let buid = self?.bookmark?.uid else { return nil }
                    guard let res = state.response.comments[buid] else { return nil }
                    return res
                }()

                return Subscribe(res: res, currentUser: state.currentUser)
            }
        }

        AnalyticsDispatcer.logging(
            .commentShowTab,
            param: ["comment_type": "\(commentType)"]
        )
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        store.unsubscribe(self)
    }

    private func setupTableview() {
        let footer = CommentFooterView()
        footer.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 80)
        tableview.tableFooterView = footer

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
        guard let buid = bookmark?.uid, buid != "" else { return }
        CommentDispatcher.fetchComments(buid: buid, type: .new)
    }

    private func fetchAdditionalComments() {
        switch commentsResponse {
        case .loading(_):
            return
        case .notYetLoading:
            // 来ないはず
            return
        case .failure(_):
            return
        case .success(let result):
            guard let buid = bookmark?.uid, result.hasMore else {
                return
            }

            CommentDispatcher.fetchComments(buid: buid, type: .add(result.lastSnapshot))
        }
    }

    private func updateFooter(mode: CommentFooterView.Mode) {
        guard let t = tableview.tableFooterView as? CommentFooterView else { return }

        if let url = bookmark?.twitterSearchUrl {
            t.set(mode: mode, url: url)
        }
    }

    @objc
    private func refresh() {
        guard let b = bookmark else { return }

        guard currentUser?.isTwitterLogin == true else {
            fetchComments()
            return
        }

        CommentRepository.execUpdateBookmarkComment(bookmarkUid: b.uid, title: b.title ?? "", url: b.url) { [weak self] result in
            switch result {
            case .failure(let error):
                self?.showAlert(title: "Error", message: error.displayMessage)
            case .success(_):
                self?.fetchComments()
            case .notYetLoading:
                return
            case .loading(_):
                return
            }
        }

        AnalyticsDispatcer.logging(
            .commentRefresh,
            param: [
                "buid": bookmark?.uid ?? "error",
                "url": bookmark?.url ?? "error",
                "comment_count": bookmark?.comment_count ?? -1,
                "comment_type": "\(commentType)"
            ]
        )
    }

    @objc
    private func close() {
        dismiss(animated: true)
    }

    private func startRefreshControll() {
        if refreshControll.isRefreshing {
            return
        }
        DispatchQueue.main.async {
            self.tableview.contentOffset = CGPoint(x:0, y: -self.refreshControll.frame.size.height)
            self.refreshControll.beginRefreshing()
        }
    }

    private func endRefreshController() {
        guard refreshControll.isRefreshing else { return }
        DispatchQueue.main.async {
            self.refreshControll.endRefreshing()
        }
    }
}

extension CommentViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentComments.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "CommentTableViewCell") as? CommentTableViewCell else {
            return UITableViewCell()
        }

        let c = currentComments[indexPath.row]
        cell.set(bookmark: bookmark, comment: c)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let c = currentComments[indexPath.row]
        guard let url = c.tweetUrl else { return }

        if currentUser?.isAdmin == true {
            openAdminMenu(url: url, comment: c)
        } else {
            openExternalLink(url: url, comment: c)
        }
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let cellHeight = self.cellHeight[indexPath] else {
            return UITableView.automaticDimension
        }
        return cellHeight
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if self.cellHeight.keys.contains(indexPath) == false {
            self.cellHeight[indexPath] = cell.frame.height
        }
    }
}

extension CommentViewController {
    private func openExternalLink(url: URL, comment: Comment) {
        DispatchQueue.main.async {
            UIApplication.shared.open(url, options: [:]) { success in
                guard success else {
                    print("open error")
                    return
                }
            }
        }

        AnalyticsDispatcer.logging(
            .commentTap,
            param: [
                "uid": comment.id,
                "twitter_user_id": comment.user.twitter_user_id,
                "favorite_count": comment.favorite_count,
                "retweet_count": comment.retweet_count,
                "has_comment": comment.has_comment ?? false
            ]
        )
    }

    private func openAdminMenu(url: URL, comment: Comment) {
        let sheet = UIAlertController(
            title: "管理者メニュー",
            message: nil,
            preferredStyle: .actionSheet
        )

        let share = UIAlertAction(title: "詳細をシェア", style: .default) { _ in
            let items: [Any] = {
                guard let buid = self.bookmark?.uid,
                    let furl = Comment.buildFirestoreDebugLink(buid: buid, cuid: comment.id) else {
                    return ["\(comment)"]
                }
                return [furl, "```\n\(comment)\n```"]
            }()

            let vc = UIActivityViewController(activityItems: items, applicationActivities: nil)
            self.present(vc, animated: true)
        }

        let normal = UIAlertAction(title: "通常ユーザの挙動", style: .default) { _ in
            self.openExternalLink(url: url, comment: comment)
        }

        let cancel = UIAlertAction(title: "キャンセル", style: .cancel) { _ in }

        sheet.addAction(share)
        sheet.addAction(normal)
        sheet.addAction(cancel)
        present(sheet, animated: true)
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
            fetchAdditionalComments()
        }
    }
}

extension CommentViewController: StoreSubscriber {
    struct Subscribe {
        var res: Repository.Response<[Comment]>?
        var currentUser: TwibuUser
    }

    typealias StoreSubscriberStateType = Subscribe

    func newState(state: Subscribe) {
        currentUser = state.currentUser

        guard let res = state.res else {
            // 初回取得前はここを通る
            commentsResponse = .notYetLoading
            render()
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
        case .success(let result):
            endRefreshController()
            if result.hasMore {
                updateFooter(mode: .hide)
            } else {
                updateFooter(mode: .finish)
            }
            tableview.reloadData()
        case .failure(let error):
            endRefreshController()
            updateFooter(mode: .finish)
            showAlert(title: "Error", message: error.displayMessage)
        case .loading(_):
            if currentComments.isEmpty {
                startRefreshControll()
                updateFooter(mode: .hide)
            } else {
                updateFooter(mode: .hasMore)
            }
        case .notYetLoading:
            endRefreshController()
            updateFooter(mode: .hide)
        }
    }
}
