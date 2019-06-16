//
//  TimelineViewController.swift
//  Twibu
//
//  Created by abeyuya on 2019/06/16.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import UIKit
import FirebaseAuth
import Parchment

final class TimelineViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!

    var item: PagingIndexItem?
    weak var delegate: PagingRootViewControllerDelegate?
    private let refreshControll = UIRefreshControl()
    private let dummyData = [
        "あいうえお",
        "かきくけこ",
        "さしすせそ"
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupLogoutButton()
    }

    private func setupLogoutButton() {
        let b = UIButton()
        b.addTarget(self, action: #selector(tapLogoutButton), for: .touchUpInside)
        b.setTitle("Logout", for: .normal)
        b.setTitleColor(.orange, for: .normal)
        view.addSubview(b)
        b.sizeToFit()
        b.center = view.center
    }

    private func setupTableView() {
        tableView.register(
            UINib.init(nibName: "TimelineCell", bundle: nil),
            forCellReuseIdentifier: "TimelineCell"
        )
        tableView.delegate = self
        tableView.dataSource = self
        refreshControll.addTarget(self, action: #selector(refresh), for: .valueChanged)
        tableView.refreshControl = refreshControll
    }

    @objc
    private func refresh() {
        guard let user = Auth.auth().currentUser else {
            showAlert(title: "Error", message: "ログインしてください")
            return
        }

        User.kickScrapeTimeline(uid: user.uid) { [weak self] result in
            self?.refreshControll.endRefreshing()
            switch result {
            case .failure(let error):
                self?.showAlert(title: "Error", message: error.localizedDescription)
            case .success(let result):
                self?.showAlert(title: "Success", message: result.debugDescription)
            }
        }
    }

    @objc
    private func tapLogoutButton() {
        let alert = UIAlertController(
            title: "",
            message: "ログアウトしますか？",
            preferredStyle: .alert
        )
        let okAction = UIAlertAction(title: "Logout", style: .destructive) { _ in
            do {
                try Auth.auth().signOut()
            } catch let signOutError as NSError {
                self.showAlert(title: "Error", message: signOutError.localizedDescription)
                return
            }
            self.delegate?.reload(item: self.item)
        }
        let cancelAction = UIAlertAction(title: "cancel", style: .cancel)
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        present(alert, animated: true)
    }

    private func showAlert(title: String?, message: String) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        let okAction = UIAlertAction(title: "OK", style: .cancel)
        alert.addAction(okAction)
        present(alert, animated: true)
    }
}

extension TimelineViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dummyData.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "TimelineCell") as? TimelineCell else {
            return UITableViewCell()
        }

        cell.titleLabel.text = dummyData[indexPath.row]
        return cell
    }
}

extension TimelineViewController: UIPageViewControllerDelegate {
}
