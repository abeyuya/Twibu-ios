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
    @IBOutlet private weak var tableView: UITableView!
    private let footerIndicator: UIActivityIndicatorView = {
        let i = UIActivityIndicatorView(style: .gray)
        i.startAnimating()
        return i
    }()

    private let refreshControll = UIRefreshControl()
    private var lastContentOffset: CGFloat = 0
    private var cellHeight: [IndexPath: CGFloat] = [:]

    private var viewModel: ArticleList!

    override func viewDidLoad() {
        super.viewDidLoad()

        setupTableView()
        setupNavigation()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        viewModel.startSubscribe()

        switch viewModel.type {
        case .category(let c):
            AnalyticsDispatcer.logging(
                .categoryLoad,
                param: ["category": c.rawValue]
            )
        default:
            break
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel.stopSubscribe()
    }

    func set(vm: ArticleList) {
        viewModel = vm
    }

    private func setupTableView() {
        tableView.tableFooterView = buildFooterView()

        tableView.register(
            UINib(nibName: "TimelineCell", bundle: nil),
            forCellReuseIdentifier: "TimelineCell"
        )
        tableView.delegate = self
        tableView.dataSource = self
        refreshControll.addTarget(self, action: #selector(refresh), for: .valueChanged)
        tableView.refreshControl = refreshControll
    }

    private func buildFooterView() -> UIView {
        let v = UIView()
        v.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 80)

        footerIndicator.translatesAutoresizingMaskIntoConstraints = false
        v.addSubview(footerIndicator)
        footerIndicator.centerXAnchor.constraint(equalTo: v.centerXAnchor).isActive = true
        footerIndicator.centerYAnchor.constraint(equalTo: v.centerYAnchor).isActive = true

        return v
    }

    @objc
    private func refresh() {
        switch viewModel.type {
        case .category(let c):
            AnalyticsDispatcer.logging(
                .categoryRefresh,
                param: ["category": c.rawValue]
            )

            if c == .timeline, viewModel.currentUser?.isTwitterLogin == true {
                refreshForLoginUser()
                return
            }

            viewModel.fetchBookmark()
        case .history:
            viewModel.fetchBookmark()
        }
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

    private func endRefreshController() {
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
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "TimelineCell") as? TimelineCell else {
            return UITableViewCell()
        }

        let b = viewModel.bookmarks[indexPath.row]
        cell.set(bookmark: b)
        return cell
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

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard let uid = viewModel.currentUser?.firebaseAuthUser?.uid else { return }
        let b = viewModel.bookmarks[indexPath.row]

        MemoDispatcher.deleteMemo(
            db: TwibuFirebase.shared.firestore,
            userUid: uid,
            bookmarkUid: b.uid
        ) { [weak self] result in
            switch result {
            case .success(_):
                break
            case .failure(let e):
                self?.showAlert(title: "Error", message: e.displayMessage)
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
                db: TwibuFirebase.shared.firestore,
                functions: TwibuFirebase.shared.functions,
                buid: b.uid,
                title: b.title ?? "",
                url: b.url,
                type: .new(limit: 100)
            )
        } else {
            CommentDispatcher.fetchComments(db: TwibuFirebase.shared.firestore, buid: b.uid, type: .new(limit: 100))
        }

        switch viewModel.type {
        case .category(let c):
            HistoryRepository.addHistory(bookmark: b)
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
        case .history:
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

// Category.timelineの場合の処理
extension CategoryViewController {
    private func refreshForLoginUser() {
        guard viewModel.currentUser?.isTwitterLogin == true,
            let uid = viewModel.currentUser?.firebaseAuthUser?.uid else {
                showAlert(title: "Error", message: TwibuError.needTwitterAuth(nil).displayMessage)
                return
        }

        UserRepository.kickScrapeTimeline(functions: TwibuFirebase.shared.functions, uid: uid) { [weak self] result in
            switch result {
            case .failure(let error):
                DispatchQueue.main.async {
                    self?.refreshControll.endRefreshing()
                    self?.showAlert(title: "Error", message: error.displayMessage)
                }
            case .success(_):
                self?.viewModel.fetchBookmark()
            }
        }
    }
}

// Category.memo, .historyの場合の処理
extension CategoryViewController {
    private func setupNavigation() {
        switch viewModel.type {
        case .category(let c):
            switch c {
            case .memo:
                navigationItem.title = c.displayString
                let editButton = UIBarButtonItem(
                    barButtonSystemItem: .edit,
                    target: self,
                    action: #selector(tapEditButton)
                )
                navigationItem.rightBarButtonItem = editButton
            default:
                break
            }
        case .history:
            navigationItem.title = "履歴"
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
    func render(state: RenderState) {
        switch state {
        case .success(let hasMore):
            self.endRefreshController()
            DispatchQueue.main.async {
                self.tableView.reloadData()
                self.footerIndicator.isHidden = self.viewModel.bookmarks.isEmpty || hasMore == false
            }
        case .failure(let error):
            self.endRefreshController()
            self.showAlert(title: "Error", message: error.displayMessage)
        case .loading:
            if viewModel.bookmarks.isEmpty {
                startRefreshControll()
            }
            DispatchQueue.main.async {
                self.footerIndicator.isHidden = self.viewModel.bookmarks.isEmpty
            }
        case .notYetLoading:
            self.startRefreshControll()
            DispatchQueue.main.async {
                self.footerIndicator.isHidden = true
            }
        }
    }
}
