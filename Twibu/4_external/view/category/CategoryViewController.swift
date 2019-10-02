//
//  CategoryViewController.swift
//  Twibu
//
//  Created by abeyuya on 2019/06/16.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import UIKit
import Embedded

final class CategoryViewController: UIViewController, StoryboardInstantiatable {
    @IBOutlet private weak var tableView: UITableView! {
        didSet {
            let footer: UIView = {
                let v = UIView()
                v.frame = CGRect(x: 0, y: 0, width: tableView.frame.width, height: 80)
                v.addSubview(footerIndicator)
                footerIndicator.centerXAnchor.constraint(equalTo: v.centerXAnchor).isActive = true
                footerIndicator.centerYAnchor.constraint(equalTo: v.centerYAnchor).isActive = true
                return v
            }()

            tableView.tableFooterView = footer
            tableView.register(
                UINib(nibName: "BookmarkCell", bundle: Bundle(for: BookmarkCell.self)),
                forCellReuseIdentifier: "BookmarkCell"
            )
            tableView.delegate = self
            tableView.dataSource = self
            tableView.refreshControl = refreshControll
        }
    }

    private let footerIndicator: UIActivityIndicatorView = {
        let i = UIActivityIndicatorView(style: .gray)
        i.startAnimating()
        i.translatesAutoresizingMaskIntoConstraints = false
        return i
    }()
    private let refreshControll: UIRefreshControl = {
        let r = UIRefreshControl()
        r.addTarget(self, action: #selector(refresh), for: .valueChanged)
        return r
    }()
    private var lastContentOffset: CGFloat = 0
    private var viewModel: ArticleList!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigation()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.startSubscribe()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel.stopSubscribe()
    }

    func set(vm: ArticleList) {
        viewModel = vm
    }

    @objc
    private func refresh() {
        switch viewModel.type {
        case .category(let c):
            AnalyticsDispatcer.logging(
                .categoryRefresh,
                param: ["category": c.rawValue]
            )
        case .timeline:
            AnalyticsDispatcer.logging(
                .categoryRefresh,
                param: ["category": "timeline"]
            )
        case .history, .memo:
            break
        }

        viewModel.fetchBookmark()
    }

    private func startRefreshControll() {
        if refreshControll.isRefreshing {
            return
        }
        DispatchQueue.main.async {
            self.tableView.contentOffset = CGPoint(x:0, y: -self.refreshControll.frame.size.height)
            self.refreshControll.beginRefreshing()
        }
    }

    private func endRefreshControll() {
        guard refreshControll.isRefreshing else { return }
        DispatchQueue.main.async {
            self.refreshControll.endRefreshing()
        }
    }
}

extension CategoryViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.bookmarks.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "BookmarkCell") as? BookmarkCell else {
            return UITableViewCell()
        }

        let b = viewModel.bookmarks[indexPath.row]
        cell.set(
            bookmark: b,
            alreadyRead: HistoryRepository.isExist(bookmarkUid: b.uid),
            showImage: true
        )

        if WebArchiver.existLocalFile(bookmarkUid: b.uid) {
            cell.set(saveState: .saved)
            return cell
        }

        if let r = viewModel.webArchiveResults.first(where: { $0.0 == b.uid }) {
            switch r.1 {
            case .success:
                cell.set(saveState: .saved)
            case .failure(_):
                cell.set(saveState: .none)
            case .progress(let progress):
                cell.set(saveState: .saving(progress))
            }
            return cell
        }

        cell.set(saveState: .none)
        return cell
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        let b = viewModel.bookmarks[indexPath.row]
        viewModel.deleteBookmark(bookmarkUid: b.uid) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(_):
                    self?.tableView.deleteRows(at: [indexPath], with: .fade)
                case .failure(let e):
                    self?.showAlert(title: "Error", message: e.displayMessage)
                }
            }
        }
    }
}

extension CategoryViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let b = viewModel.bookmarks[indexPath.row]
        let vc = WebViewController.initFromStoryBoard()
        vc.set(bookmark: b)
        navigationController?.pushViewController(vc, animated: true)

        if let isLogin = viewModel.currentUser?.isTwitterLogin, isLogin {
            CommentDispatcher.updateAndFetchComments(
                buid: b.uid,
                title: b.title ?? "",
                url: b.url,
                type: .new(limit: 100)
            )
        } else {
            CommentDispatcher.fetchComments(
                buid: b.uid,
                type: .new(limit: 100)
            )
        }

        switch viewModel.type {
        case .category(let c):
            HistoryDispatcher.addNewHistory(bookmark: b)
            AnalyticsDispatcer.logging(
                .bookmarkTap,
                param: [
                    "category": c.rawValue,
                    "buid": b.uid,
                    "url": b.url,
                    "comment_count": b.comment_count ?? -1,
                ]
            )
        case .timeline:
            HistoryDispatcher.addNewHistory(bookmark: b)
            AnalyticsDispatcer.logging(
                .bookmarkTap,
                param: [
                    "category": "timeline",
                    "buid": b.uid,
                    "url": b.url,
                    "comment_count": b.comment_count ?? -1,
                ]
            )
        case .history, .memo:
            break
        }
    }

    private static let humanScrollOffset: CGFloat = 100

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let currentPoint = scrollView.contentOffset
        let contentSize = scrollView.contentSize
        let frameSize = scrollView.frame
        let maxOffSet = contentSize.height - frameSize.height

        defer {
            lastContentOffset = currentPoint.y
        }

        // 無限スクロールするためのイベント発火
        let distanceToBottom = maxOffSet - currentPoint.y
        if distanceToBottom < 600 {
            viewModel.fetchAdditionalBookmarks()
        }

        if currentPoint.y >= maxOffSet {
            // print("hit the bottom")
            return
        }

        if currentPoint.y <= 0 {
            // print("hit the top")
            // self.navigationController?.setNavigationBarHidden(false, animated: true)
            return
        }

        let delta = currentPoint.y - lastContentOffset
        if 0 < delta, delta < CategoryViewController.humanScrollOffset {
            // print("Scrolled down")
//            if navigationController?.isNavigationBarHidden == false {
//                self.navigationController?.setNavigationBarHidden(true, animated: true)
//            }
            return
        }

        // print("Scrolled up")
    }

    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if velocity.y < 0 {
            navigationController?.setNavigationBarHidden(false, animated: true)
        }
    }
}

extension CategoryViewController: UIPageViewControllerDelegate {}

// Category.memo, .historyの場合の処理
private extension CategoryViewController {
    private func setupNavigation() {
        switch viewModel.type {
        case .category, .timeline:
            break
        case .history:
            navigationItem.title = "履歴"
            let editButton = UIBarButtonItem(
                barButtonSystemItem: .edit,
                target: self,
                action: #selector(tapEditButton)
            )
            navigationItem.rightBarButtonItem = editButton
        case .memo:
            navigationItem.title = "メモ"
            let editButton = UIBarButtonItem(
                barButtonSystemItem: .edit,
                target: self,
                action: #selector(tapEditButton)
            )
            navigationItem.rightBarButtonItem = editButton
        }
    }

    @objc
    private func tapEditButton() {
        tableView.setEditing(!tableView.isEditing, animated: true)
    }
}

extension CategoryViewController: ArticleListDelegate {
    func update(results: [(String, WebArchiver.SaveResult)]) {
        let updatedUids = results.map { $0.0 }
        var indexes: [Int] = []
        for (index, b) in viewModel.bookmarks.enumerated() {
            if updatedUids.contains(b.uid) {
                indexes.append(index)
            }
        }
        if indexes.isEmpty {
            return
        }
        let indexPaths = indexes.map { IndexPath(row: $0, section: 0) }
        tableView.reloadRows(at: indexPaths, with: .none)
    }

    func render(state: ArticleRenderState) {
        switch state {
        case .success:
            endRefreshControll()
            DispatchQueue.main.async {
                self.tableView.reloadData()
                self.footerIndicator.isHidden = false
            }
        case .failure(let error):
            endRefreshControll()
            showAlert(title: "Error", message: error.displayMessage)
        case .loading:
            startRefreshControll()
            DispatchQueue.main.async {
                self.footerIndicator.isHidden = true
            }
        case .additionalLoading:
            endRefreshControll()
            DispatchQueue.main.async {
                self.footerIndicator.isHidden = false
            }
        case .notYetLoading:
            startRefreshControll()
            DispatchQueue.main.async {
                self.footerIndicator.isHidden = true
            }
        }
    }
}
