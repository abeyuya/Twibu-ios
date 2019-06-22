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

final class CategoryViewController: UIViewController, StoryboardInstantiatable {

    @IBOutlet weak var tableView: UITableView!

    var item: PagingIndexItem?
    weak var delegate: PagingRootViewControllerDelegate?
    private let refreshControll = UIRefreshControl()
    private var bookmarks: [Bookmark] = []

    private var beginingPoint = CGPoint(x: 0, y: 0)

    private var category: Category? {
        guard let i = item?.index,
            let category = Category(index: Category.calcLogicalIndex(physicalIndex: i)) else {
                return nil
        }
        return category
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        fetchBookmark()

        if category == .timeline, let u = Auth.auth().currentUser, !u.providerData.isEmpty {
            setupLogoutButton()
        } else {

        }
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
        BookmarkRepository.fetchBookmark(category: category) { [weak self] result in
            self?.refreshControll.endRefreshing()

            switch result {
            case .failure(let error):
                self?.showAlert(title: "Error", message: error.displayMessage)
            case .success(let bookmarks):
                self?.bookmarks = bookmarks
                self?.tableView.reloadData()
            }
        }
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
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension CategoryViewController: UITableViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        beginingPoint = scrollView.contentOffset
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let currentPoint = scrollView.contentOffset
        let contentSize = scrollView.contentSize
        let frameSize = scrollView.frame
        let maxOffSet = contentSize.height - frameSize.height

        if currentPoint.y >= maxOffSet {
            // print("hit the bottom")
            self.navigationController?.setNavigationBarHidden(false, animated: true)
        } else if beginingPoint.y < currentPoint.y {
            // print("Scrolled down")
            self.navigationController?.setNavigationBarHidden(true, animated: true)
        } else {
            // print("Scrolled up")
        }
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
