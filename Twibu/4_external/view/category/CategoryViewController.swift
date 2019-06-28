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

    var item: PagingIndexItem?
    weak var delegate: PagingRootViewControllerDelegate?
    private let refreshControll = UIRefreshControl()
    private var bookmarksResponse: Repository.Response<[Bookmark]> = .notYetLoading

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

        if category == .timeline, UserRepository.isTwitterLogin() {
            setupLogoutButton()
        }

        store.subscribe(self) { [weak self] subcription in
            subcription.select { state in
                guard let c = self?.category else { return nil }
                return state.response.bookmarks[c]
            }
        }
    }

    deinit {
        store.unsubscribe(self)
    }

    private func setupTableView() {
        tableView.tableFooterView = UIView()
        tableView.register(
            UINib(nibName: "TimelineCell", bundle: nil),
            forCellReuseIdentifier: "TimelineCell"
        )
        tableView.delegate = self
        tableView.dataSource = self
        refreshControll.addTarget(self, action: #selector(refresh), for: .valueChanged)
        tableView.refreshControl = refreshControll
    }

    private func fetchBookmark() {
        guard let category = category else { return }
        BookmarkDispatcher.fetchBookmark(category: category)
    }

    @objc
    private func refresh() {
        if category == .timeline, UserRepository.isTwitterLogin() {
            refreshForLoginUser()
            return
        }

        fetchBookmark()
    }

    private func fetchAdditionalBookmarks() {
        guard bookmarks.count < 30 else { return }
    }

    private func startRefreshControll() {
        if refreshControll.isRefreshing {
            return
        }
        DispatchQueue.main.async {
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

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let b = bookmarks[indexPath.row]
        let vc = WebViewController.initFromStoryBoard()
        vc.set(bookmark: b)
        CommentDispatcher.updateBookmarkComment(bookmarkUid: b.uid, url: b.url)
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension CategoryViewController: UITableViewDelegate {
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
        if 0 < delta {
            // print("Scrolled down")
            if navigationController?.isNavigationBarHidden == false {
                self.navigationController?.setNavigationBarHidden(true, animated: true)
            }
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

extension CategoryViewController: UIPageViewControllerDelegate {
}

// Category.timelineの場合の処理
extension CategoryViewController {
    private func setupLogoutButton() {
        let b = UIButton()
        b.addTarget(self, action: #selector(tapLogoutButton), for: .touchUpInside)
        b.setTitle("Logout", for: .normal)
        b.setTitleColor(.orange, for: .normal)
        view.addSubview(b)
        b.sizeToFit()
        b.center = view.center
    }

    @objc
    private func tapLogoutButton() {
        let alert = UIAlertController(
            title: "",
            message: "ログアウトしますか？",
            preferredStyle: .alert
        )
        let okAction = UIAlertAction(title: "Logout", style: .destructive) { _ in
            guard let user = Auth.auth().currentUser else {
                self.showAlert(title: "Error", message: TwibuError.needFirebaseAuth("ログアウトしようとした").displayMessage)
                return
            }

            user.unlink(fromProvider: "twitter.com") { [weak self] user, error in
                if let error = error {
                    self?.showAlert(title: "Error", message: TwibuError.signOut(error.localizedDescription).displayMessage)
                    return
                }

                // TODO: access_tokenとか使えなくなるので消したい
                self?.delegate?.reload(item: self?.item)
            }
        }
        let cancelAction = UIAlertAction(title: "cancel", style: .cancel)
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        present(alert, animated: true)
    }

    private func refreshForLoginUser() {
        guard UserRepository.isTwitterLogin() else {
            showAlert(title: "Error", message: TwibuError.needTwitterAuth(nil).displayMessage)
            return
        }

        guard let user = Auth.auth().currentUser else {
            showAlert(title: "Error", message: TwibuError.needFirebaseAuth(nil).displayMessage)
            return
        }

        UserRepository.kickScrapeTimeline(uid: user.uid) { [weak self] result in
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
    typealias StoreSubscriberStateType = Repository.Response<[Bookmark]>?

    func newState(state: Repository.Response<[Bookmark]>?) {
        guard let res = state else {
            // 初回取得前はここを通る
            bookmarksResponse = .notYetLoading
            fetchBookmark()
            return
        }

        bookmarksResponse = res
        render()
    }

    func render() {
        DispatchQueue.main.async {
            switch self.bookmarksResponse {
            case .success(_):
                self.endRefreshController()
                self.tableView.reloadData()
            case .failure(let error):
                self.endRefreshController()
                self.showAlert(title: "Error", message: error.displayMessage)
            case .loading(_):
                self.startRefreshControll()
            case .notYetLoading:
                self.startRefreshControll()
            }
        }
    }
}
