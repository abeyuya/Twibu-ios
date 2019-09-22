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

    func replace(vc: UIViewController, completion: @escaping () -> Void) {
        DispatchQueue.main.async {
            if let childViewController = self.children.first {
                childViewController.willMove(toParent: nil)
                childViewController.view.subviews.forEach { $0.removeFromSuperview() }
                childViewController.view.removeFromSuperview()
                childViewController.children.forEach { $0.removeFromParent() }
                childViewController.removeFromParent()
            }

            self.view.subviews.forEach { $0.removeFromSuperview() }
            self.set(vc: vc, completion: completion)
        }
    }

    private func set(vc: UIViewController, completion: @escaping () -> Void) {
        DispatchQueue.main.async {
            self.addChild(vc)
            self.view.addSubview(vc.view)
            vc.view.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor).isActive = true
            vc.view.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
            vc.view.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
            vc.view.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor).isActive = true
            vc.didMove(toParent: self)
            completion()
        }
    }

    private func setupView() {
        view.backgroundColor = .mainBackground

        UINavigationBar.appearance().titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor.mainTint
        ]
        UINavigationBar.appearance().barTintColor = .mainBackground
        UINavigationBar.appearance().tintColor = .mainTint

        UIToolbar.appearance().barTintColor = .white
        UIToolbar.appearance().tintColor = .mainTint
    }
}
