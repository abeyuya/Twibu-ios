//
//  WebViewController.swift
//  Twibu
//
//  Created by abeyuya on 2019/06/17.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import UIKit
import WebKit

class WebViewController: UIViewController, StoryboardInstantiatable {

    private let webview = WKWebView()
    private var bookmark: Bookmark!
    private var beginingPoint = CGPoint(x: 0, y: 0)

    override func viewDidLoad() {
        super.viewDidLoad()

        setupWebview()
        setupCommentLoadButton()
        setupNavigation()
        setupToolbar()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
        navigationController?.setToolbarHidden(true, animated: true)
    }

    private func setupWebview() {
        webview.scrollView.delegate = self
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

    private func setupNavigation() {
        title = bookmark.title
    }

    private func setupToolbar() {
        navigationController?.setToolbarHidden(false, animated: true)
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

        guard let url = URL(string: bookmark.url) else {
            assert(false)
            return
        }

        let request = URLRequest(url: url)
        webview.load(request)
    }
}

extension WebViewController: WKNavigationDelegate {
}

extension WebViewController: UIScrollViewDelegate {
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
            self.navigationController?.setToolbarHidden(false, animated: true)
        } else if beginingPoint.y < currentPoint.y {
            // print("Scrolled down")
            self.navigationController?.setNavigationBarHidden(true, animated: true)
            self.navigationController?.setToolbarHidden(true, animated: true)
        } else {
            //print("Scrolled up")
        }
    }

    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if velocity.y < 0 {
            navigationController?.setNavigationBarHidden(false, animated: true)
            navigationController?.setToolbarHidden(false, animated: true)
        }
    }
}
