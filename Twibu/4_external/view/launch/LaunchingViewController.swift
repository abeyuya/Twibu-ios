//
//  LaunchingViewController.swift
//  Twibu
//
//  Created by abeyuya on 2019/06/22.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import UIKit
import FirebaseAuth
import SideMenuSwift

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
            let nav = UINavigationController(rootViewController: vc)
            let side = SideMenuViewController.initFromStoryBoard()
            let allVc = SideMenuController(contentViewController: nav, menuViewController: side)
            root.replace(vc: allVc)
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

//        SideMenuController.preferences.basic.enablePanGesture = true
    }
}
