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

final class CategoryViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!

    var item: PagingIndexItem?
    weak var delegate: PagingRootViewControllerDelegate?
    private let refreshControll = UIRefreshControl()
    private var bookmarks: [Bookmark] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        fetchBookmark()
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
        guard let i = item?.index,
            let category = Category(index: Category.calcLogicalIndex(physicalIndex: i)) else {
                return
        }

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
        fetchBookmark()
    }
}

extension CategoryViewController: UITableViewDelegate, UITableViewDataSource {
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
        let storyboard = UIStoryboard(name: "WebViewController", bundle: nil)
        let vc = storyboard.instantiateInitialViewController() as! WebViewController
        vc.set(bookmark: b)
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension CategoryViewController: UIPageViewControllerDelegate {
}
