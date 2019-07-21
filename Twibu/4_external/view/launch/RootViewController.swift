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
        setupView()
    }

    func replace(vc: UIViewController) {
        DispatchQueue.main.async {
            if let childViewController = self.children.first {
                childViewController.willMove(toParent: nil)
                childViewController.view.removeFromSuperview()
                childViewController.view.subviews.forEach { $0.removeFromSuperview() }
                childViewController.removeFromParent()
                childViewController.children.forEach { $0.removeFromParent() }
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

    private func setupView() {
        view.backgroundColor = .white

        UINavigationBar.appearance().titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor.mainBlack
        ]
        UINavigationBar.appearance().barTintColor = .white
        UINavigationBar.appearance().tintColor = .mainBlack

        UIToolbar.appearance().barTintColor = .white
        UIToolbar.appearance().tintColor = .mainBlack
    }
}
