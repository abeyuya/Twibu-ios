//
//  LaunchingViewController.swift
//  Twibu
//
//  Created by abeyuya on 2019/06/22.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import UIKit
import FirebaseAuth

class LaunchingViewController: UIViewController, StoryboardInstantiatable {

    override func viewDidLoad() {
        super.viewDidLoad()

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

        let storyboard = UIStoryboard(name: "PagingRootViewController", bundle: nil)
        let vc = storyboard.instantiateInitialViewController()!
        root.replace(vc: vc)
    }
}
