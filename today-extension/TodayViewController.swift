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

final class TodayViewController: UIViewController, NCWidgetProviding {

    var bookmarks: [Bookmark] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        extensionContext?.widgetLargestAvailableDisplayMode = .expanded

        guard TwibuUserDefaults.shared.getFirebaseUid() != nil else {
            renderError()
            return
        }
    }

    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        guard let uid = TwibuUserDefaults.shared.getFirebaseUid() else {
            completionHandler(.failed)
            return
        }

        BookmarkRepository.fetchBookmark(category: .all, uid: uid, type: .new(30)) { [weak self] result in
            switch result {
            case .notYetLoading, .loading(_):
                completionHandler(.failed)
                Logger.print("通らないはず")
                return
            case .failure(let error):
                completionHandler(.failed)
                Logger.print(error)
                return
            case .success(let res):
                let top4 = res.item
                    .sorted(by: { $0.comment_count ?? 0 > $1.comment_count ?? 0 })
                    .prefix(4)

                if top4.isEmpty {
                    DispatchQueue.main.async {
                        self?.renderError()
                    }
                    completionHandler(.noData)
                    return
                }

                self?.bookmarks = Array(top4)

                DispatchQueue.main.async {
                    self?.render()
                }
                completionHandler(.newData)
            }
        }
    }

    func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        switch activeDisplayMode {
        case .compact:
            self.preferredContentSize = maxSize
        case .expanded:
            self.preferredContentSize = CGSize(width: 0, height: 500)
        @unknown default:
            self.preferredContentSize = maxSize
        }
        render()
    }
}

extension TodayViewController {

    private func renderError() {
        view.subviews.forEach { $0.removeFromSuperview() }
        let l = UILabel()
        l.text = "ニュースが取得できませんでした"
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(l)
        l.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12).isActive = true
        l.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 12).isActive = true
        l.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: 12).isActive = true
        l.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 12).isActive = true
    }

    private func render() {
        view.subviews.forEach { $0.removeFromSuperview() }

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
            renderCompact()
        case .expanded:
            renderExpand()
        @unknown default:
            renderExpand()
        }
    }

    private func renderCompact() {
        guard let b = bookmarks.first else {
            renderError()
            return
        }

        let v = TodayCell()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.set(bookmark: b)
        view.addSubview(v)

        v.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        v.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        v.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        v.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }

    private func renderExpand() {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.translatesAutoresizingMaskIntoConstraints = false

        bookmarks.forEach { b in
            let v = TodayCell()
            v.translatesAutoresizingMaskIntoConstraints = false
            v.set(bookmark: b)
            stack.addArrangedSubview(v)
        }

        view.addSubview(stack)
        stack.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        stack.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        stack.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        stack.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }
}
