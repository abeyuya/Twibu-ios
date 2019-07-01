//
//  LaunchingViewController.swift
//  Twibu
//
//  Created by abeyuya on 2019/06/22.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import UIKit
import FirebaseAuth
import AMScrollingNavbar

class LaunchingViewController: UIViewController, StoryboardInstantiatable {

    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()

        if Auth.auth().currentUser != nil {
            moveToPagingRootView()
            return
        }

        Auth.auth().signInAnonymously() { [weak self] result, error in
            if let error = error {
                let te = TwibuError.needFirebaseAuth(error.localizedDescription)
                self?.showAlert(title: "Error", message: te.displayMessage)
                return
            }

            self?.moveToPagingRootView()
        }
    }

    private func moveToPagingRootView() {
        guard let d = UIApplication.shared.delegate as? AppDelegate,
            let root = d.window?.rootViewController as? RootViewController else {
                return
        }

        DispatchQueue.main.async {
            let vc = PagingRootViewController.initFromStoryBoard()
            let nav = ScrollingNavigationController()
            nav.setViewControllers([vc], animated: true)
            root.replace(vc: nav)
        }
    }

    private func setupView() {
        UINavigationBar.appearance().titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor.mainBlack
        ]
        UINavigationBar.appearance().barTintColor = .white
        UINavigationBar.appearance().tintColor = .mainBlack

        UIToolbar.appearance().barTintColor = .white
        UIToolbar.appearance().tintColor = .mainBlack
    }
}
