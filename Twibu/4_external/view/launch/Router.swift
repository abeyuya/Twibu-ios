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

    func showLauncingView() {
        let vc = LaunchingViewController.initFromStoryBoard()
        rootVc?.replace(vc: vc)
    }

    func showPagingRootView() {
        let vc = PagingRootViewController.initFromStoryBoard()
        let nav = UINavigationController(rootViewController: vc)
        rootVc?.replace(vc: nav)
    }

    func openBookmarkWebFromUrlScheme(vc: UIViewController) {
        UserDispatcher.setupUser() { _ in
            DispatchQueue.main.async {
                let navi: UINavigationController? = {
                    if let n = self.rootVc?.children.last as? UINavigationController {
                        return n
                    }

                    self.showPagingRootView()
                    return self.rootVc?.children.last as? UINavigationController
                }()

                navi?.pushViewController(vc, animated: true)
            }
        }
    }
}
