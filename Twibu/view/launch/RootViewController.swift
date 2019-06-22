//
//  RootViewController.swift
//  Twibu
//
//  Created by abeyuya on 2019/06/22.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import UIKit

final class RootViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        let vc = LaunchingViewController.initFromStoryBoard()
        set(vc: vc)
    }

    func replace(vc: UIViewController) {
        if let childViewController = self.children.first {
            childViewController.willMove(toParent: nil)
            childViewController.view.removeFromSuperview()
            childViewController.removeFromParent()
        }

        set(vc: vc)
    }

    private func set(vc: UIViewController) {
        DispatchQueue.main.async {
            self.addChild(vc)
            vc.view.frame = UIScreen.main.bounds
            self.view.addSubview(vc.view)
            vc.didMove(toParent: self)
        }
    }
}
