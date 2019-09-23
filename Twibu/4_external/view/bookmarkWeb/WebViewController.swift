//
//  WebViewController.swift
//  Twibu
//
//  Created by abeyuya on 2019/06/17.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import UIKit
import WebKit
import ReSwift
import SwiftIcons
import BadgeSwift
import PKHUD
import Embedded

private let iconSize: CGFloat = 25

final class WebViewController: UIViewController, StoryboardInstantiatable {
    private enum ViewMode {
        case online, offline
    }

    private let webview = WKWebView()
    private var bookmark: Bookmark!
    private var currentUser: TwibuUser?
    private var lastContentOffset: CGFloat = 0
    private var isShowComment = false
    private var viewMode: ViewMode = .online

    private let commentBadge: BadgeSwift = {
        let badge = BadgeSwift()
        badge.translatesAutoresizingMaskIntoConstraints = false
        badge.textColor = .white
        badge.font = .systemFont(ofSize: 11)

        return badge
    }()

    private lazy var commentContainerView: UIView = {
        let vc = CommentRootViewController<FirestoreCommentListViewModel>.build(bookmark: bookmark)
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        addChild(vc)
        vc.view.frame = container.frame

        container.addSubview(vc.view)
        vc.didMove(toParent: self)

        return container
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        setupWebview()
        setupNavigation()
        setupToolbar()

        store.subscribe(self) { [weak self] subcription in
            subcription.select { state in
                let bms = AppState.toFlat(bookmarks: state.response.bookmarks)
                let b = bms.first { $0.uid == self?.bookmark.uid }
                return Subscribe(bookmark: b, currentUser: state.currentUser)
            }
        }
    }

    deinit {
        store.unsubscribe(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if navigationController?.isNavigationBarHidden == true {
            navigationController?.setNavigationBarHidden(false, animated: true)
        }
        if navigationController?.isToolbarHidden == true {
            navigationController?.setToolbarHidden(false, animated: true)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if navigationController?.isNavigationBarHidden == true {
            navigationController?.setNavigationBarHidden(false, animated: true)
        }
        if navigationController?.isToolbarHidden == false {
            navigationController?.setToolbarHidden(true, animated: true)
        }
    }

    func set(bookmark: Bookmark) {
        self.bookmark = bookmark

        guard let url = URL(string: bookmark.url) else {
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
        setNavigationTitle()
    }

    private func setNavigationTitle() {
        DispatchQueue.main.async {
            if self.viewIfLoaded?.window == nil {
                return
            }

            self.navigationItem.titleView?.removeFromSuperview()
            let v = UIStackView()
            v.axis = .vertical
            v.spacing = 4

            let l1 = UILabel()
            l1.text = self.bookmark.trimmedTitle ?? "no title"
            l1.textAlignment = .center
            v.addArrangedSubview(l1)

            let l2 = UILabel()
            l2.text = self.bookmark.url.replacingOccurrences(
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
        let backRoot: UIBarButtonItem = {
            let b = UIButton()
            b.setIcon(
                icon: .icofont(.thinDoubleLeft),
                iconSize: nil,
                color: .mainTint,
                backgroundColor: .clear,
                forState: .normal
            )
            b.addTarget(self, action: #selector(tapBackRootButton), for: .touchUpInside)
            return UIBarButtonItem(customView: b)
        }()

        let backPrev: UIBarButtonItem = {
            let b = UIButton()
            b.setIcon(
                icon: .icofont(.thinLeft),
                iconSize: nil,
                color: .mainTint,
                backgroundColor: .clear,
                forState: .normal
            )
            b.addTarget(self, action: #selector(tapBackPrevButton), for: .touchUpInside)
            return UIBarButtonItem(customView: b)
        }()

        let commentButton: UIBarButtonItem = {
            let b = UIButton()
            updateCommentButton(button: b, isShowComment: false)
            b.addTarget(self, action: #selector(tapCommentButton(_:)), for: .touchUpInside)
            if let count = bookmark.comment_count {
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
            backRoot,
            space,
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
        guard !bookmark.uid.isEmpty else {
            showAlert(title: nil, message: "コメントが取得できませんでした")
            return
        }

        if isShowComment {
            hideCommentView()
            commentBadge.isHidden = false
        } else {
            showCommentView()
            commentBadge.isHidden = true
        }

        updateCommentButton(button: sender, isShowComment: isShowComment)
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
            title: viewMode == .online ? "PDFで読む" : "WEBサイトを読み込む",
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
        guard let uid = currentUser?.firebaseAuthUser?.uid else { return }
        guard !bookmark.uid.isEmpty else {
            showAlert(title: nil, message: "メモの読み込みに失敗しました")
            return
        }

        let vc = MemoViewController.initFromStoryBoard()
        vc.modalTransitionStyle = .crossDissolve
        vc.modalPresentationStyle = .overCurrentContext

        let param = MemoViewController.Param(
            db: TwibuFirebase.shared.firestore,
            userUid: uid,
            bookmarkUid: bookmark.uid
        )
        vc.setParam(param: param)

        present(vc, animated: true)
    }

    private func saveAsPdf() {
        if viewMode == .offline {
            showAlert(title: nil, message: "WEBサイトとして閲覧中でないとPDFは保存できません")
            return
        }

        HUD.show(.progress)
        WebArchiveDispatcher.save(webView: webview, bookmarkUid: bookmark.uid) { [weak self] result in
            switch result {
            case .success:
                HUD.flash(.success)
                self?.loadPageOffline()
                self?.viewMode = .offline
            case .failure(let error):
                HUD.flash(.labeledError(title: nil, subtitle: error.displayMessage))
            case .progress(_):
                break
            }
        }
    }

    private func tapModeButton() {
        switch viewMode {
        case .online:
            if localFileUrl() == nil {
                showAlert(title: nil, message: "PDFが保存されていません")
                return
            }
            loadPageOffline()
            viewMode = .offline

        case .offline:
            guard let url = URL(string: bookmark.url) else {
                showAlert(title: nil, message: "URLが取得できませんでした")
                return
            }
            loadPageOnline(url: url)
            viewMode = .online
        }
    }

    private func showCommentView() {
        isShowComment = true
        webview.scrollView.scrollsToTop = false
        UIView.transition(
            with: view,
            duration: 0.5,
            options: .transitionCurlDown,
            animations: {
                self.view.addSubview(self.commentContainerView)
                self.commentContainerView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
                self.commentContainerView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
                self.commentContainerView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
                self.commentContainerView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor).isActive = true
            },
            completion: { _ in }
        )

        AnalyticsDispatcer.logging(
            .commentShow,
            param: [
                "buid": bookmark.uid,
                "url": bookmark.url,
                "comment_count": bookmark.comment_count ?? -1
            ]
        )
    }

    private func hideCommentView() {
        isShowComment = false
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

        AnalyticsDispatcer.logging(
            .commentHide,
            param: [
                "buid": bookmark.uid,
                "url": bookmark.url,
                "comment_count": bookmark.comment_count ?? -1
            ]
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

        AnalyticsDispatcer.logging(
            .share,
            param: [
                "buid": bookmark.uid,
                "url": bookmark.url,
                "comment_count": bookmark.comment_count ?? -1
            ]
        )
    }

    private func loadPageOnline(url: URL) {
        let request = URLRequest(url: url)
        webview.load(request)
    }

    private func localFileUrl() -> URL? {
        if let localFileUrl = WebArchiver.buildLocalFileUrl(bookmarkUid: bookmark.uid),
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
        if 0 < delta, delta < WebViewController.humanScrollOffset, isShowComment == false {
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

extension WebViewController: StoreSubscriber {
    struct Subscribe {
        var bookmark: Bookmark?
        var currentUser: TwibuUser
    }

    typealias StoreSubscriberStateType = Subscribe

    func newState(state: Subscribe) {
        currentUser = state.currentUser
        guard let b = state.bookmark else { return }

        self.bookmark = b
        setNavigationTitle()

        if let c = b.comment_count {
            setBadgeCount(count: c)
        }
    }
}
