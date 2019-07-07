//
//  CommentRootViewController.swift
//  Twibu
//
//  Created by abeyuya on 2019/07/06.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import UIKit
import Parchment

final class CommentRootViewController: UIViewController {

    private var pagingViewController: FixedPagingViewController!
    var bookmark: Bookmark!

    enum CommentType {
        case left, right

        var title: String {
            switch self {
            case .left:
                return "みんなのコメント"
            case .right:
                return "その他のツイート"
            }
        }
    }

    static func build(bookmark: Bookmark) -> CommentRootViewController {
        let vc = CommentRootViewController()
        vc.bookmark = bookmark
        return vc
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupPaging()
    }

    private func setupPaging() {
        pagingViewController = FixedPagingViewController(viewControllers: [
            buildCommentVc(type: .left),
            buildCommentVc(type: .right)
        ])

        view.addSubview(pagingViewController.view)
        pagingViewController.didMove(toParent: self)
        pagingViewController.view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            pagingViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pagingViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pagingViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            pagingViewController.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
        ])

        pagingViewController.textColor = .tabUnselectGray
        pagingViewController.selectedTextColor = .twitter
        pagingViewController.indicatorColor = .twitter
        pagingViewController.backgroundColor = .tabBgGray
        pagingViewController.menuBackgroundColor = .tabBgGray
        pagingViewController.borderOptions = .hidden
    }

    private func buildCommentVc(type: CommentType) -> UIViewController {
        let vc = CommentViewController.initFromStoryBoard()
        vc.bookmark = bookmark
        vc.commentType = type
        vc.title = type.title
        return vc
    }
}
