//
//  Router.swift
//  Twibu
//
//  Created by abeyuya on 2019/07/21.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import Foundation
import UIKit
import FirebaseAuth
import Embedded

final class Router {
    static let shared = Router()
    private init() {}

    private let rootVc: RootViewController? = {
        guard let d = UIApplication.shared.delegate as? AppDelegate,
            let root = d.window?.rootViewController as? RootViewController else {
                return nil
        }

        return root
    }()

    func showLauncingView(completion: @escaping () -> Void) {
        let vc = LaunchingViewController.initFromStoryBoard()
        rootVc?.replace(vc: vc, completion: completion)
    }

    func showPagingRootView(completion: @escaping () -> Void) {
        let vc = PagingRootViewController.initFromStoryBoard()
        let nav = UINavigationController(rootViewController: vc)
        rootVc?.replace(vc: nav, completion: completion)
    }

    private func getPresentingNavigation() -> UINavigationController? {
        let n = self.rootVc?.children.last(where: { c in
            return c is UINavigationController
        })

        return n as? UINavigationController
    }

    func openBookmarkWebFromUrlScheme(vc: UIViewController) {
        UserDispatcher.setupUser() { _ in
            DispatchQueue.main.async {
                if let navi = self.getPresentingNavigation() {
                    navi.popViewController(animated: false)
                    navi.pushViewController(vc, animated: false)
                    return
                }

                self.showPagingRootView() {
                    self.getPresentingNavigation()?.pushViewController(vc, animated: false)
                }
            }
        }
    }

    func topViewController(vc: UIViewController?) -> UIViewController? {
        guard let vc = vc ?? rootVc else { return nil }
        if let presented = vc.presentedViewController {
            return topViewController(vc: presented)
        }
        return vc
    }

    func addHeadlessWebView(webView: UIView) {
        webView.isHidden = true
        rootVc?.view.addSubview(webView)
    }
}
