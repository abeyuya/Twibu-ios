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
    private var bookmarksResponse: ResponseState<[Bookmark]> = .notYetLoading

    private var lastContentOffset: CGFloat = 0

    private var category: Category? {
        guard let i = item?.index,
            let category = Category(index: Category.calcLogicalIndex(physicalIndex: i)) else {
                return nil
        }
        return category
    }

    private var bookmarks: [Bookmark] {
        switch bookmarksResponse {
        case .success(let bookmarks): return bookmarks
        case .loading(let bookmarks): return bookmarks
        case .faillure(_): return []
        case .notYetLoading: return []
        }
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
        refreshControll.beginRefreshing()
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

        if currentPoint.y >= maxOffSet {
            // print("hit the bottom")
            return
        }

        if currentPoint.y <= 0 {
            // print("hit the top")
            self.navigationController?.setNavigationBarHidden(false, animated: true)
            return
        }

        let delta = currentPoint.y - lastContentOffset
        if 0 < delta {
            // print("Scrolled down")
            self.navigationController?.setNavigationBarHidden(true, animated: true)
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
                self?.refreshControll.endRefreshing()
                self?.showAlert(title: "Error", message: error.displayMessage)
            case .success(_):
                self?.fetchBookmark()
            }
        }
    }
}

extension CategoryViewController: StoreSubscriber {
    typealias StoreSubscriberStateType = ResponseState<[Bookmark]>?

    func newState(state: ResponseState<[Bookmark]>?) {
        guard let res = state else {
            // 初回取得前はここを通る
            bookmarksResponse = .notYetLoading
            fetchBookmark()
            return
        }

        bookmarksResponse = res

        DispatchQueue.main.async {
            self.render()
        }
    }

    func render() {
        switch bookmarksResponse {
        case .success(_):
            refreshControll.endRefreshing()
            tableView.reloadData()
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
