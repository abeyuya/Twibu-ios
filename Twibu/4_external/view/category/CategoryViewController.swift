//
//  CategoryViewController.swift
//  Twibu
//
//  Created by abeyuya on 2019/06/16.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import UIKit
import FirebaseAuth
import Parchment
import ReSwift

final class CategoryViewController: UIViewController, StoryboardInstantiatable {

    @IBOutlet weak var tableView: UITableView!
    private let footerIndicator: UIActivityIndicatorView = {
        let i = UIActivityIndicatorView(style: .gray)
        i.startAnimating()
        return i
    }()

    var item: PagingIndexItem?
    private let refreshControll = UIRefreshControl()
    private var bookmarksResponse: Repository.Response<[Bookmark]> = .notYetLoading
    private var currentUser: TwibuUser?

    private var lastContentOffset: CGFloat = 0

    private var category: Category? {
        guard let i = item?.index,
            let category = Category(index: Category.calcLogicalIndex(physicalIndex: i)) else {
                return nil
        }
        return category
    }

    private var bookmarks: [Bookmark] {
        return bookmarksResponse.item ?? []
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupTableView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        store.subscribe(self) { [weak self] subcription in
            subcription.select { state in
                let res: Repository.Response<[Bookmark]>? = {
                    guard let c = self?.category else { return nil }
                    return state.response.bookmarks[c]
                }()

                return Subscribe(res: res, currentUser: state.currentUser)
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        store.unsubscribe(self)
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

    private func fetchBookmark() {
        guard let category = category, let uid = currentUser?.firebaseAuthUser?.uid else { return }
        BookmarkDispatcher.fetchBookmark(category: category, uid: uid, type: .new)
    }

    @objc
    private func refresh() {
        AnalyticsDispatcer.logging(
            .categoryRefresh,
            param: ["category": category?.rawValue ?? "error"]
        )

        if category == .timeline, currentUser?.isTwitterLogin == true {
            refreshForLoginUser()
            return
        }

        fetchBookmark()
    }

    private func fetchAdditionalBookmarks() {
//        guard category == .all else { return }
//        guard bookmarks.count < 50 else { return }

        switch bookmarksResponse {
        case .loading(_):
            return
        case .notYetLoading:
            // 来ないはず
            return
        case .failure(_):
            return
        case .success(let result):
            guard let category = category,
                let uid = currentUser?.firebaseAuthUser?.uid,
                result.hasMore else { return }

            BookmarkDispatcher.fetchBookmark(
                category: category,
                uid: uid,
                type: .add(result.lastSnapshot)
            )
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
        return bookmarks.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "TimelineCell") as? TimelineCell else {
            return UITableViewCell()
        }

        let b = bookmarks[indexPath.row]
        cell.set(bookmark: b)
        return cell
    }
}

extension CategoryViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let b = bookmarks[indexPath.row]
        let vc = WebViewController.initFromStoryBoard()
        vc.set(bookmark: b)
        navigationController?.pushViewController(vc, animated: true)

        if currentUser?.isTwitterLogin == true {
            CommentDispatcher.updateBookmarkComment(
                bookmarkUid: b.uid,
                title: b.title ?? "",
                url: b.url,
                oldCount: b.comment_count ?? 0
            )
        }

        AnalyticsDispatcer.logging(
            .bookmarkTap,
            param: [
                "category": category?.rawValue ?? "error",
                "buid": b.uid,
                "url": b.url,
                "comment_count": b.comment_count ?? -1,
            ]
        )
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
        if distanceToBottom < 300 {
            fetchAdditionalBookmarks()
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
        guard currentUser?.isTwitterLogin == true,
            let uid = currentUser?.firebaseAuthUser?.uid else {
                showAlert(title: "Error", message: TwibuError.needTwitterAuth(nil).displayMessage)
                return
        }

        UserRepository.kickScrapeTimeline(uid: uid) { [weak self] result in
            switch result {
            case .failure(let error):
                DispatchQueue.main.async {
                    self?.refreshControll.endRefreshing()
                    self?.showAlert(title: "Error", message: error.displayMessage)
                }
            case .success(_):
                self?.fetchBookmark()
            }
        }
    }
}

extension CategoryViewController: StoreSubscriber {
    struct Subscribe {
        var res: Repository.Response<[Bookmark]>?
        var currentUser: TwibuUser
    }

    typealias StoreSubscriberStateType = Subscribe

    func newState(state: Subscribe) {
        currentUser = state.currentUser

        guard let res = state.res else {
            // 初回取得前はここを通る
            bookmarksResponse = .notYetLoading
            render()
            fetchBookmark()
            return
        }

        bookmarksResponse = res
        DispatchQueue.main.async {
            self.render()
        }
    }

    func render() {
        switch self.bookmarksResponse {
        case .success(_):
            self.endRefreshController()
            DispatchQueue.main.async {
                self.tableView.reloadData()
                self.footerIndicator.isHidden = self.bookmarks.isEmpty
            }
        case .failure(let error):
            self.endRefreshController()
            self.showAlert(title: "Error", message: error.displayMessage)
        case .loading(_):
            if bookmarks.isEmpty {
                startRefreshControll()
            }
            DispatchQueue.main.async {
                self.footerIndicator.isHidden = self.bookmarks.isEmpty
            }
        case .notYetLoading:
            self.startRefreshControll()
            DispatchQueue.main.async {
                self.footerIndicator.isHidden = true
            }
        }
    }
}
