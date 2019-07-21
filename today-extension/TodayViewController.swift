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

        perform(completionHandler: nil)
    }

    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        perform(completionHandler: completionHandler)
    }

    func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        perform() { _ in }
        switch activeDisplayMode {
        case .compact:
            self.preferredContentSize = maxSize
        case .expanded:
            self.preferredContentSize = CGSize(width: 0, height: 400)
        @unknown default:
            self.preferredContentSize = maxSize
        }
    }
}

private extension TodayViewController {

    private func perform(completionHandler: ((NCUpdateResult) -> Void)?) {
        checkFirebaseLogin() { [weak self] loginResult in
            switch loginResult {
            case .failure(let e):
                Logger.print(e)
                self?.renderError()
                completionHandler?(.failed)
            case .success(let user):
                self?.fetchBookmark(uid: user.uid) { fetchResult in
                    switch fetchResult {
                    case .failure(let e):
                        Logger.print(e)
                        self?.renderError()
                        completionHandler?(.failed)
                    case .success(let bookmarks):
                        self?.render(bookmarks: bookmarks)

                        if bookmarks.isEmpty {
                            completionHandler?(.noData)
                        } else {
                            completionHandler?(.newData)
                        }
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
            self.view.subviews.forEach { $0.removeFromSuperview() }
            let l = UILabel()
            l.text = "ニュースが取得できませんでした"
            l.textAlignment = .center
            l.translatesAutoresizingMaskIntoConstraints = false
            self.view.addSubview(l)
            l.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 12).isActive = true
            l.leftAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leftAnchor, constant: 12).isActive = true
            l.rightAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.rightAnchor, constant: 12).isActive = true
            l.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: 12).isActive = true
        }
    }

    private func render(bookmarks: [Bookmark]) {
        DispatchQueue.main.async {
            self.view.subviews.forEach { $0.removeFromSuperview() }
        }

        if bookmarks.isEmpty {
            renderError()
            return
        }

        guard let mode = extensionContext?.widgetActiveDisplayMode else {
            renderError()
            return
        }

        switch mode {
        case .compact:
            guard let b = bookmarks.first else {
                self.renderError()
                return
            }
            renderCompact(bookmark: b)
        case .expanded:
            renderExpand(bookmarks: bookmarks)
        @unknown default:
            renderExpand(bookmarks: bookmarks)
        }
    }

    private func renderCompact(bookmark: Bookmark) {
        DispatchQueue.main.async {
            let v = TodayCell()
            v.translatesAutoresizingMaskIntoConstraints = false
            v.set(bookmark: bookmark, showImage: true)
            self.view.addSubview(v)

            v.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
            v.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
            v.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
            v.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        }
    }

    private func renderExpand(bookmarks: [Bookmark]) {
        DispatchQueue.main.async {
            let stack = UIStackView()
            stack.axis = .vertical
            stack.translatesAutoresizingMaskIntoConstraints = false

            bookmarks.enumerated().forEach { (index, b) in
                let v = TodayCell()
                v.translatesAutoresizingMaskIntoConstraints = false
                v.set(bookmark: b, showImage: index == 0)
                stack.addArrangedSubview(v)
            }

            self.view.addSubview(stack)
            stack.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
            stack.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
            stack.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
            stack.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        }
    }
}
