//
//  CommentViewController.swift
//  Twibu
//
//  Created by abeyuya on 2019/06/20.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import UIKit
import SafariServices

final class CommentViewController: UIViewController, StoryboardInstantiatable {
    @IBOutlet private weak var tableview: UITableView! {
        didSet {
            let footer = CommentFooterView()
            footer.frame = CGRect(x: 0, y: 0, width: tableview.frame.width, height: 80)
            tableview.tableFooterView = footer
            tableview.delegate = self
            tableview.dataSource = self
            tableview.register(
                UINib(nibName: "CommentTableViewCell", bundle: Bundle(for: Self.self)),
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
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel.stopSubscribe()
    }

    private func updateFooter(mode: CommentFooterView.Mode) {
        guard let t = tableview.tableFooterView as? CommentFooterView else { return }

        if let url = viewModel.bookmark?.twitterSearchUrl {
            t.set(mode: mode) {
                let vc = SFSafariViewController(url: url)
                self.topViewController(vc: nil)?.present(vc, animated: true)
            }
        }
    }

    @objc
    private func refresh() {
        viewModel.fetchComments()
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
        viewModel.didTapComment(comment: c)
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
    func openExternalLink(comment: Comment) {
        guard let url = comment.tweetUrl else { return }
        DispatchQueue.main.async {
            let vc = SFSafariViewController(url: url)

            if let nav = self.navigationController {
                nav.pushViewController(vc, animated: true)
                return
            }

            self.topViewController(vc: nil)?.present(vc, animated: true)
        }
    }

    private func topViewController(vc: UIViewController?) -> UIViewController? {
        guard let vc = vc ?? UIApplication.shared.keyWindow?.rootViewController else { return nil }
        if let presented = vc.presentedViewController {
            return topViewController(vc: presented)
        }
        return vc
    }

    func openAdminMenu(comment: Comment) {
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
            self.openExternalLink(comment: comment)
        }

        let cancel = UIAlertAction(title: "キャンセル", style: .cancel) { _ in }

        sheet.addAction(share)
        sheet.addAction(normal)
        sheet.addAction(cancel)
        present(sheet, animated: true)
    }

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
