//
//  CommentViewController.swift
//  Twibu
//
//  Created by abeyuya on 2019/06/20.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import UIKit
import SafariServices
import Embedded

final class CommentViewController: UIViewController, StoryboardInstantiatable {
    @IBOutlet private weak var tableview: UITableView! {
        didSet {
            let footer = CommentFooterView()
            footer.frame = CGRect(x: 0, y: 0, width: tableview.frame.width, height: 80)
            tableview.tableFooterView = footer
            tableview.delegate = self
            tableview.dataSource = self
            tableview.register(
                UINib(nibName: "CommentTableViewCell", bundle: nil),
                forCellReuseIdentifier: "CommentTableViewCell"
            )
            tableview.refreshControl = refreshControll
        }
    }

    private let refreshControll: UIRefreshControl = {
        let r = UIRefreshControl()
        r.addTarget(self, action: #selector(refresh), for: .valueChanged)
        return r
    }()
    private var cellHeight: [IndexPath: CGFloat] = [:]

    private var viewModel: CommentList!

    func set(vm: CommentList) {
        viewModel = vm
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.startSubscribe()

        // 初回表示時に追加読み込みが必要ならする
        if tableview.contentSize.height < tableview.frame.height, !viewModel.currentComments.isEmpty {
            viewModel.fetchAdditionalComments()
        }

        AnalyticsDispatcer.logging(
            .commentShowTab,
            param: ["comment_type": "\(viewModel.commentType)"]
        )
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel.stopSubscribe()
    }

    private func updateFooter(mode: CommentFooterView.Mode) {
        guard let t = tableview.tableFooterView as? CommentFooterView else { return }

        if let url = viewModel.bookmark?.twitterSearchUrl {
            t.set(mode: mode, url: url)
        }
    }

    @objc
    private func refresh() {
        guard let b = viewModel.bookmark else { return }

        guard viewModel.currentUser?.isTwitterLogin == true else {
            viewModel.fetchComments()
            return
        }

        CommentDispatcher.updateAndFetchComments(
            functions: TwibuFirebase.shared.functions,
            buid: b.uid,
            title: b.title ?? "",
            url: b.url,
            type: .new(limit: 100)
        )

        AnalyticsDispatcer.logging(
            .commentRefresh,
            param: [
                "buid": viewModel.bookmark?.uid ?? "error",
                "url": viewModel.bookmark?.url ?? "error",
                "comment_count": viewModel.bookmark?.comment_count ?? -1,
                "comment_type": "\(viewModel.commentType)"
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
        return viewModel.currentComments.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "CommentTableViewCell") as? CommentTableViewCell else {
            return UITableViewCell()
        }

        let c = viewModel.currentComments[indexPath.row]
        cell.set(bookmark: viewModel.bookmark, comment: c)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let c = viewModel.currentComments[indexPath.row]
        guard let url = c.tweetUrl else { return }

        if viewModel.currentUser?.isAdmin == true {
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
            let vc = SFSafariViewController(url: url)
            Router.shared.topViewController(vc: nil)?.present(vc, animated: true)
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

        let share = UIAlertAction(title: "firestoreリンク", style: .default) { _ in
            let items: [Any] = {
                guard let buid = self.viewModel.bookmark?.uid,
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
            viewModel.fetchAdditionalComments()
            return
        }
    }
}

extension CommentViewController: CommentListDelegate {
    internal func render(state: CommentRenderState) {
        switch state {
        case .success(let hasMore):
            endRefreshController()
            if hasMore {
                updateFooter(mode: .hide)
            } else {
                updateFooter(mode: .finish)
            }
            tableview.reloadData()
        case .failure(let error):
            endRefreshController()
            updateFooter(mode: .finish)
            showAlert(title: "Error", message: error.displayMessage)
        case .loading:
            guard viewModel.currentComments.isEmpty else {
                if refreshControll.isRefreshing {
                    updateFooter(mode: .hide)
                } else {
                    updateFooter(mode: .hasMore)
                }
                return
            }

            startRefreshControll()
            updateFooter(mode: .hide)
        case .notYetLoading:
            endRefreshController()
            updateFooter(mode: .hide)
            viewModel.fetchComments()
        }
    }
}
