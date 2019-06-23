//
//  WebViewController.swift
//  Twibu
//
//  Created by abeyuya on 2019/06/17.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import UIKit
import WebKit

final class WebViewController: UIViewController, StoryboardInstantiatable {

    private let webview = WKWebView()
    private var bookmark: Bookmark!
    private var lastContentOffset: CGFloat = 0
    private var isShowComment = false

    override func viewDidLoad() {
        super.viewDidLoad()

        setupWebview()
        setupNavigation()
        setupToolbar()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setNavigationBarHidden(false, animated: true)
        navigationController?.setToolbarHidden(false, animated: true)
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

    private func setupNavigation() {
        title = bookmark.title
    }

    private func setupToolbar() {
        navigationController?.setToolbarHidden(false, animated: true)

        let backRoot = UIBarButtonItem(
            barButtonSystemItem: .camera,
            target: self,
            action: #selector(tapBackRootButton)
        )
        let backPrev = UIBarButtonItem(
            barButtonSystemItem: .bookmarks,
            target: self,
            action: #selector(tapBackPrevButton)
        )
        let commentButton = UIBarButtonItem(
            barButtonSystemItem: .search,
            target: self,
            action: #selector(tapCommentButton)
        )
        let shareButton = UIBarButtonItem(
            barButtonSystemItem: .action,
            target: self,
            action: #selector(tapShareButton)
        )
        let space = UIBarButtonItem(
            barButtonSystemItem: .flexibleSpace,
            target: nil,
            action: nil
        )

        toolbarItems = [
            backRoot,
            space,
            backPrev,
            space,
            commentButton,
            space,
            shareButton
        ]
    }

    private let commentViewController = CommentViewController.initFromStoryBoard()

    private lazy var commentContainerView: UIView  = {
        commentViewController.bookmark = bookmark

        let container = UIView(frame: view.frame)
        addChild(commentViewController)
        commentViewController.view.frame = container.frame
        container.addSubview(commentViewController.view)
        commentViewController.didMove(toParent: self)

        return container
    }()

    @objc
    private func tapCommentButton() {
        if isShowComment {
            hideCommentView()
        } else {
            showCommentView()
        }
    }

    private func showCommentView() {
        isShowComment = true
        UIView.transition(
            with: view,
            duration: 0.5,
            options: .transitionCurlDown,
            animations: {
                self.view.addSubview(self.commentContainerView)
        },
            completion: { _ in }
        )
    }

    private func hideCommentView() {
        isShowComment = false
        UIView.transition(
            with: view,
            duration: 0.5,
            options: .transitionCurlUp,
            animations: {
                self.commentContainerView.removeFromSuperview()
        },
            completion: { _ in }
        )
    }

    @objc
    private func tapBackPrevButton() {
        webview.goBack()
    }

    @objc
    private func tapBackRootButton() {
        guard let item = webview.backForwardList.backList.first else { return }
        webview.go(to: item)
    }

    @objc
    private func tapShareButton() {
        guard let url = URL(string: bookmark.url) else { return }
        let vc = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        present(vc, animated: true)
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
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {

        guard navigationAction.navigationType == .linkActivated else {
            decisionHandler(.allow)
            return
        }

        guard let f = navigationAction.targetFrame, f.isMainFrame else {
                // target="_blank" の場合
                webview.load(navigationAction.request)
                decisionHandler(.cancel)
                return
        }

        decisionHandler(.allow)
    }
}

extension WebViewController: UIScrollViewDelegate {
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
            self.navigationController?.setNavigationBarHidden(false, animated: true)
            self.navigationController?.setToolbarHidden(false, animated: true)
            return
        }

        if currentPoint.y <= 0 {
            // print("hit the top")
            self.navigationController?.setNavigationBarHidden(false, animated: true)
            self.navigationController?.setToolbarHidden(false, animated: true)
            return
        }

        let delta = currentPoint.y - lastContentOffset
        if 0 < delta {
            // print("Scrolled down")
            self.navigationController?.setNavigationBarHidden(true, animated: true)
            self.navigationController?.setToolbarHidden(true, animated: true)
            return
        }

        // print("Scrolled up")
    }

    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if velocity.y < 0 {
            navigationController?.setNavigationBarHidden(false, animated: true)
            navigationController?.setToolbarHidden(false, animated: true)
        }
    }
}