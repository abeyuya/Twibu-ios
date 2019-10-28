//
//  WebViewController.swift
//  Twibu
//
//  Created by abeyuya on 2019/06/17.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import UIKit
import WebKit
import SwiftIcons
import BadgeSwift
import PKHUD
import Embedded

private let iconSize: CGFloat = 25

final class WebViewController: UIViewController, StoryboardInstantiatable {
    private let webview = WKWebView()
    private var lastContentOffset: CGFloat = 0
    private var viewModel: WebViewModel!

    private let commentBadge: BadgeSwift = {
        let badge = BadgeSwift()
        badge.translatesAutoresizingMaskIntoConstraints = false
        badge.textColor = .white
        badge.font = .systemFont(ofSize: 11)

        return badge
    }()

    private lazy var commentContainerView: UIView = {
        let vc = CommentRootViewController<FirestoreCommentListViewModel>.build(bookmark: viewModel.bookmark)
        addChild(vc)
        vc.didMove(toParent: self)

        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(vc.view)
        vc.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            vc.view.topAnchor.constraint(equalTo: container.topAnchor),
            vc.view.leftAnchor.constraint(equalTo: container.leftAnchor),
            vc.view.rightAnchor.constraint(equalTo: container.rightAnchor),
            vc.view.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        return container
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupWebview()
        setupNavigation()
        setupToolbar()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if navigationController?.isNavigationBarHidden == true {
            navigationController?.setNavigationBarHidden(false, animated: true)
        }
        if navigationController?.isToolbarHidden == true {
            navigationController?.setToolbarHidden(false, animated: true)
        }

        viewModel.startSubscribe()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if navigationController?.isNavigationBarHidden == true {
            navigationController?.setNavigationBarHidden(false, animated: true)
        }
        if navigationController?.isToolbarHidden == false {
            navigationController?.setToolbarHidden(true, animated: true)
        }

        viewModel.stopSubscribe()
    }

    func set(viewModel: WebViewModel) {
        self.viewModel = viewModel

        guard let url = URL(string: viewModel.bookmark.url) else {
            assert(false)
            return
        }

        loadPageOnline(url: url)
    }
}

private extension WebViewController {
    private func setupWebview() {
        webview.navigationDelegate = self
        webview.scrollView.delegate = self
        webview.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(webview)
        webview.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        webview.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        webview.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        webview.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }

    private func setupNavigation() {
        navigationController?.interactivePopGestureRecognizer?.delegate = self
        setNavigationTitle(title: viewModel.bookmark.title, url: viewModel.bookmark.url)
    }

    private func setNavigationTitle(title: String?, url: String?) {
        DispatchQueue.main.async {
            if self.viewIfLoaded?.window == nil {
                return
            }

            self.navigationItem.titleView?.removeFromSuperview()
            let v = UIStackView()
            v.axis = .vertical
            v.spacing = 4

            let l1 = UILabel()
            l1.text = title ?? "no title"
            l1.textAlignment = .center
            v.addArrangedSubview(l1)

            let l2 = UILabel()
            l2.text = url?.replacingOccurrences(
                of: "^https?://(.+)$",
                with: "$1",
                options: .regularExpression,
                range: nil
            )
            l2.textColor = .originSecondaryLabel
            l2.font = .systemFont(ofSize: 12)
            l2.textAlignment = .center
            v.addArrangedSubview(l2)

            self.navigationItem.titleView = v
        }
    }

    private func setupToolbar() {
        let backPrev = UIBarButtonItem(
            barButtonSystemItem: .rewind,
            target: self,
            action: #selector(tapBackPrevButton)
        )

        let commentButton: UIBarButtonItem = {
            let b = UIButton()
            updateCommentButton(button: b, isShowComment: false)
            b.addTarget(self, action: #selector(tapCommentButton(_:)), for: .touchUpInside)
            if let count = viewModel.bookmark.comment_count {
                commentBadge.text = String(count)
                b.addSubview(commentBadge)
                commentBadge.centerXAnchor.constraint(equalTo: b.trailingAnchor).isActive = true
                commentBadge.topAnchor.constraint(equalTo: b.topAnchor).isActive = true
            }
            return UIBarButtonItem(customView: b)
        }()

        let shareButton = UIBarButtonItem(
            barButtonSystemItem: .action,
            target: self,
            action: #selector(tapShareButton)
        )
        let bookmarkButton = UIBarButtonItem(
            barButtonSystemItem: .bookmarks,
            target: self,
            action: #selector(tapBookmarksButton)
        )
        let space = UIBarButtonItem(
            barButtonSystemItem: .flexibleSpace,
            target: nil,
            action: nil
        )

        toolbarItems = [
            backPrev,
            space,
            commentButton,
            space,
            shareButton,
            space,
            bookmarkButton
        ]
    }

    private func updateCommentButton(button: UIButton, isShowComment: Bool) {
        let icon: FontType = isShowComment
            ? .fontAwesomeSolid(.comment)
            : .fontAwesomeRegular(.comment)

        button.setIcon(
            icon: icon,
            iconSize: iconSize,
            color: .mainTint,
            backgroundColor: .clear,
            forState: .normal
        )
    }

    @objc
    private func tapCommentButton(_ sender: UIButton) {
        guard !viewModel.bookmark.uid.isEmpty else {
            showAlert(title: nil, message: "コメントが取得できませんでした")
            return
        }

        if viewModel.isShowComment {
            hideCommentView()
            commentBadge.isHidden = false
        } else {
            showCommentView()
            commentBadge.isHidden = true
        }

        updateCommentButton(button: sender, isShowComment: viewModel.isShowComment)
    }

    @objc
    private func tapBookmarksButton(_ sender: UIButton) {
        let s = UIAlertController(
            title: nil,
            message: nil,
            preferredStyle: .actionSheet
        )

        let memo = UIAlertAction(
            title: "メモ",
            style: .default
        ) { _ in self.tapWriteButton() }

        let save = UIAlertAction(
            title: "PDFとして保存する",
            style: .default
        ) { _ in self.saveAsPdf() }

        let mode = UIAlertAction(
            title: viewModel.viewMode == .online ? "PDFで読む" : "WEBサイトを読み込む",
            style: .default
        ) { _ in self.tapModeButton() }

        let cancel = UIAlertAction(
            title: "キャンセル",
            style: .cancel
        ) { _ in }

        s.addAction(memo)
        s.addAction(save)
        s.addAction(mode)
        s.addAction(cancel)
        present(s, animated: true)
    }

    private func tapWriteButton() {
        guard let uid = viewModel.currentUser?.firebaseAuthUser?.uid else { return }
        guard !viewModel.bookmark.uid.isEmpty else {
            showAlert(title: nil, message: "メモの読み込みに失敗しました")
            return
        }

        let vc = MemoViewController.initFromStoryBoard()
        vc.modalTransitionStyle = .crossDissolve
        vc.modalPresentationStyle = .overCurrentContext
        vc.setParam(userUid: uid, bookmarkUid: viewModel.bookmark.uid)
        present(vc, animated: true)
    }

    private func saveAsPdf() {
        if viewModel.viewMode == .offline {
            showAlert(title: nil, message: "WEBサイトとして閲覧中でないとPDFは保存できません")
            return
        }

        HUD.show(.progress)
        WebArchiveDispatcher.save(webView: webview, bookmarkUid: viewModel.bookmark.uid) { [weak self] result in
            switch result {
            case .success:
                HUD.flash(.success)
                self?.loadPageOffline()
                self?.viewModel.viewMode = .offline
            case .failure(let error):
                HUD.flash(.labeledError(title: nil, subtitle: error.displayMessage))
            case .progress(_):
                break
            }
        }
    }

    private func tapModeButton() {
        switch viewModel.viewMode {
        case .online:
            if localFileUrl() == nil {
                showAlert(title: nil, message: "PDFが保存されていません")
                return
            }
            loadPageOffline()
            viewModel.viewMode = .offline

        case .offline:
            guard let url = URL(string: viewModel.bookmark.url) else {
                showAlert(title: nil, message: "URLが取得できませんでした")
                return
            }
            loadPageOnline(url: url)
            viewModel.viewMode = .online
        }
    }

    private func showCommentView() {
        viewModel.isShowComment = true
        webview.scrollView.scrollsToTop = false
        UIView.transition(
            with: view,
            duration: 0.5,
            options: .transitionCurlDown,
            animations: {
                self.view.addSubview(self.commentContainerView)
                NSLayoutConstraint.activate([
                    self.commentContainerView.topAnchor.constraint(equalTo: self.view.topAnchor),
                    self.commentContainerView.leftAnchor.constraint(equalTo: self.view.leftAnchor),
                    self.commentContainerView.rightAnchor.constraint(equalTo: self.view.rightAnchor),
                    self.commentContainerView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor)
                ])
            },
            completion: { _ in }
        )

        AnalyticsDispatcer.logging(
            .commentShow,
            param: [
                "buid": viewModel.bookmark.uid,
                "url": viewModel.bookmark.url,
                "comment_count": viewModel.bookmark.comment_count ?? -1
            ]
        )
    }

    private func hideCommentView() {
        viewModel.isShowComment = false
        webview.scrollView.scrollsToTop = true
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
        guard let url = URL(string: viewModel.bookmark.url) else { return }
        let vc = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        present(vc, animated: true)

        AnalyticsDispatcer.logging(
            .share,
            param: [
                "buid": viewModel.bookmark.uid,
                "url": viewModel.bookmark.url,
                "comment_count": viewModel.bookmark.comment_count ?? -1
            ]
        )
    }

    private func loadPageOnline(url: URL) {
        let request = URLRequest(url: url)
        webview.load(request)
    }

    private func localFileUrl() -> URL? {
        if let localFileUrl = WebArchiver.buildLocalFileUrl(bookmarkUid: viewModel.bookmark.uid),
            FileManager.default.fileExists(atPath: localFileUrl.path) {
                return localFileUrl
        }
        return nil
    }

    private func loadPageOffline() {
        guard let localFileUrl = localFileUrl() else {
            showAlert(title: nil, message: "PDFが保存されていません")
            return
        }

        webview.loadFileURL(localFileUrl, allowingReadAccessTo: localFileUrl)
    }

    private func setBadgeCount(count: Int) {
        DispatchQueue.main.async {
            self.commentBadge.text = String(count)
        }
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
    // webview読み込みによって自動でスクロール判定されちゃうので、その対応
    private static let humanScrollOffset: CGFloat = 100

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
            return
        }

        if currentPoint.y <= 0 {
            // print("hit the top")
            // if navigationController?.isNavigationBarHidden == true {
            //     self.navigationController?.setNavigationBarHidden(false, animated: true)
            // }
            // if navigationController?.isToolbarHidden == true {
            //     self.navigationController?.setToolbarHidden(false, animated: true)
            // }
            return
        }

        let delta = currentPoint.y - lastContentOffset
        if 0 < delta, delta < WebViewController.humanScrollOffset, viewModel.isShowComment == false {
            // print("Scrolled down")
//            if navigationController?.isNavigationBarHidden == false {
//                self.navigationController?.setNavigationBarHidden(true, animated: true)
//            }
            if navigationController?.isToolbarHidden == false {
                self.navigationController?.setToolbarHidden(true, animated: true)
            }
            return
        }

        // print("Scrolled up")
    }

    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if velocity.y < 0 {
            if navigationController?.isNavigationBarHidden == true {
                navigationController?.setNavigationBarHidden(false, animated: true)
            }
            if navigationController?.isToolbarHidden == true {
                navigationController?.setToolbarHidden(false, animated: true)
            }
        }
    }
}

extension WebViewController: UIGestureRecognizerDelegate {
    // これを許すとエッジスワイプ中に縦スクロールできちゃって気持ち悪い
    // This is necessary because without it, subviews of your top controller can
    // cancel out your gesture recognizer on the edge.
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

extension WebViewController: WebViewModelDelegate {
    func updateNavigation(title: String?, url: String?) {
        setNavigationTitle(title: title, url: url)
    }

    func renderBadgeCount(count: Int) {
        setBadgeCount(count: count)
    }
}
