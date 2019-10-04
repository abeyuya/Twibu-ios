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
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.delegate = self
            tableView.dataSource = self
            tableView.tableFooterView = UIView()
            tableView.register(
                UINib(nibName: "\(ArticleCell.self)", bundle: Bundle(for: ArticleCell.self)),
                forCellReuseIdentifier: "cell"
            )
        }
    }

    private var bookmarks: [Bookmark] = []

    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        BookmarkApiRepository.fetchBookmarks { [weak self] result in
            switch result {
            case .failure(let e):
                Logger.print(e)
                completionHandler(.failed)
            case .success(let bookmarks):
                if Bookmark.isEqual(a: self?.bookmarks ?? [], b: bookmarks) {
                    self?.reloadTable()
                    completionHandler(.noData)
                    return
                }

                DispatchQueue.main.async {
                    self?.bookmarks = bookmarks
                    self?.reloadTable()
                }

                if bookmarks.isEmpty {
                    completionHandler(.noData)
                    return
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
            let height = min(maxSize.height, tableView.contentSize.height)
            self.preferredContentSize = CGSize(width: 0, height: height)
        @unknown default:
            self.preferredContentSize = maxSize
        }
    }
}

private extension TodayViewController {
    private func reloadTable() {
        DispatchQueue.main.async {
            UIView.animate(
                withDuration: 0,
                animations: { self.tableView.reloadData() },
                completion: { finished in
                    guard finished else { return }
                    self.extensionContext?.widgetLargestAvailableDisplayMode = .expanded
                }
            )
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
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as? ArticleCell else {
            return UITableViewCell()
        }

        let b = bookmarks[indexPath.row]
        // 画像が重くてメモリ制限引っかかるので常にoffに
        cell.set(bookmark: b, alreadyRead: false, showImage: false)
        return cell
    }
}
