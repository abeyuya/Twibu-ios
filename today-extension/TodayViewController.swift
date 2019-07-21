//
//  TodayViewController.swift
//  today-extension
//
//  Created by abeyuya on 2019/07/20.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import UIKit
import NotificationCenter
import Embedded
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

final class TodayViewController: UIViewController, NCWidgetProviding {

    @IBOutlet weak var tableView: UITableView!

    private var bookmarks: [Bookmark] = []

    public let firestore: Firestore = {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }

        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        settings.dispatchQueue = DispatchQueue.global()

        let db = Firestore.firestore()
        db.settings = settings

        return db
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        extensionContext?.widgetLargestAvailableDisplayMode = .expanded

        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }

        setupTableview()
        loginAndFetch() { [weak self] result in
            switch result {
            case .failure(let e):
                Logger.print(e)
            case .success(let bookmarks):
                self?.bookmarks = bookmarks

                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
            }
        }
    }

    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        loginAndFetch() { [weak self] result in
            switch result {
            case .failure(let e):
                Logger.print(e)
                completionHandler(.failed)
            case .success(let bookmarks):
                self?.bookmarks = bookmarks

                if bookmarks.isEmpty {
                    completionHandler(.noData)
                    return
                }

                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                    completionHandler(.newData)
                }
            }
        }
    }

    func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        self.tableView.reloadData()
        switch activeDisplayMode {
        case .compact:
            self.preferredContentSize = maxSize
        case .expanded:
            let height = max(tableView.contentSize.height, 400)
            self.preferredContentSize = CGSize(width: 0, height: height)
        @unknown default:
            self.preferredContentSize = maxSize
        }
    }
}

private extension TodayViewController {

    private func setupTableview() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()

        tableView.register(
            UINib(nibName: "TodayCell", bundle: nil),
            forCellReuseIdentifier: "cell"
        )
    }

    private func loginAndFetch(completion: @escaping (Result<[Bookmark]>) -> Void) {
        checkFirebaseLogin() { [weak self] loginResult in
            switch loginResult {
            case .failure(let e):
                completion(.failure(e))
            case .success(let user):
                self?.fetchBookmark(uid: user.uid) { fetchResult in
                    switch fetchResult {
                    case .failure(let e):
                        completion(.failure(e))
                    case .success(let bookmarks):
                        completion(.success(bookmarks))
                    }
                }
            }
        }
    }

    private func fetchBookmark(uid: String, completion: @escaping (Result<[Bookmark]>) -> Void) {
        BookmarkRepository.fetchBookmark(
            db: firestore,
            category: .all,
            uid: uid,
            type: .new(30)
        ) { result in
            switch result {
            case .notYetLoading, .loading(_):
                let e = TwibuError.firestoreError("通らないはず")
                completion(.failure(e))
                return
            case .failure(let e):
                completion(.failure(e))
                return
            case .success(let res):
                let top4 = res.item
                    .sorted(by: { $0.comment_count ?? 0 > $1.comment_count ?? 0 })
                    .prefix(4)

                completion(.success(Array(top4)))
            }
        }
    }

    private func checkFirebaseLogin(completion: @escaping (Result<User>) -> Void) {
        if let user = Auth.auth().currentUser {
            completion(.success(user))
            return
        }

        Auth.auth().signInAnonymously() { result, error in
            if let error = error {
                let te = TwibuError.needFirebaseAuth(error.localizedDescription)
                completion(.failure(te))
                return
            }

            guard let user = result?.user else {
                let e = TwibuError.needFirebaseAuth("匿名ログインしたもののユーザ情報が取れない")
                completion(.failure(e))
                return
            }

            completion(.success(user))
        }
    }

    private func renderError() {
        DispatchQueue.main.async {
            let l = UILabel()
            l.text = "ニュースが取得できませんでした"
            l.textAlignment = .center
            l.translatesAutoresizingMaskIntoConstraints = false
            self.view.addSubview(l)
            l.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
            l.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
        }
    }
}

extension TodayViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let b = bookmarks[indexPath.row]
        guard let c = extensionContext,
            let query = b.dictionary?.queryString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
            let url = URL(string: "twibu://?\(query)") else { return }
        c.open(url)
    }
}

extension TodayViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let mode = extensionContext?.widgetActiveDisplayMode, mode == .expanded else {
            return min(bookmarks.count, 1)
        }
        return bookmarks.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as? TodayCell else {
            return UITableViewCell()
        }

        let b = bookmarks[indexPath.row]
        cell.set(bookmark: b, showImage: indexPath.row == 0)
        return cell
    }
}
