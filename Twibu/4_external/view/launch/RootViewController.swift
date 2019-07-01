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
        DispatchQueue.main.async {
            if let childViewController = self.children.first {
                childViewController.willMove(toParent: nil)
                childViewController.view.removeFromSuperview()
                childViewController.removeFromParent()
            }

            self.set(vc: vc)
        }
    }

    private func set(vc: UIViewController) {
        DispatchQueue.main.async {
            self.addChild(vc)
            self.view.addSubview(vc.view)
            vc.view.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor).isActive = true
            vc.view.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
            vc.view.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
            vc.view.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor).isActive = true
            vc.didMove(toParent: self)
        }
    }
}
