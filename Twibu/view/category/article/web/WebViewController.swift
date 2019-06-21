//
//  WebViewController.swift
//  Twibu
//
//  Created by abeyuya on 2019/06/17.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import UIKit
import WebKit

class WebViewController: UIViewController {

    private let webview = WKWebView()
    private var bookmark: Bookmark!

    override func viewDidLoad() {
        super.viewDidLoad()

        setupWebview()
        setupCommentLoadButton()
    }

    private func setupWebview() {
        webview.navigationDelegate = self
        webview.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(webview)
        webview.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        webview.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        webview.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        webview.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }

    private func setupCommentLoadButton() {
        let b = UIButton()
        b.addTarget(self, action: #selector(tapCommentButton), for: .touchUpInside)
        b.setTitle("コメントを見る", for: .normal)
        b.setTitleColor(.orange, for: .normal)
        view.addSubview(b)
        b.sizeToFit()
        b.center = view.center
    }

    @objc
    private func tapCommentButton() {
        let storyboard = UIStoryboard(name: "CommentViewController", bundle: nil)
        let nav = storyboard.instantiateInitialViewController() as! UINavigationController
        guard let vc = nav.viewControllers.first as? CommentViewController else {
            return
        }
        vc.bookmark = bookmark

        DispatchQueue.main.async {
//            self.present(nav, animated: true)
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }

    func set(bookmark: Bookmark) {
        self.bookmark = bookmark

        guard let displayUrl = bookmark.url.expanded_url, let url = URL(string: displayUrl) else {
            assert(false)
            return
        }

        let request = URLRequest(url: url)
        webview.load(request)
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

extension WebViewController: WKNavigationDelegate {

}
