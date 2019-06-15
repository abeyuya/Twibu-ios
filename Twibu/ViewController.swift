//
//  ViewController.swift
//  Twibu
//
//  Created by abeyuya on 2019/06/15.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import UIKit
import FirebaseAuth
import TwitterKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

//        let button: UIButton = {
//            let b = UIButton()
//            b.setTitle("認証する", for: .normal)
//            b.translatesAutoresizingMaskIntoConstraints = false
//            b.addTarget(self, action: #selector(tapAuthButton), for: .touchUpInside)
//            return b
//        }()

        let button = TWTRLogInButton() { session, error in
            guard let session = session else {
                // TODO: error
                print(error)
                return
            }
            let cred = TwitterAuthProvider.credential(
                withToken: session.authToken,
                secret: session.authTokenSecret
            )

            Auth.auth().signIn(with: cred) { result, error in
                if let error = error {
                    // TODO: error
                    print(error)
                    return
                }
                print(result)
                print(result)
            }
        }

        button.center = view.center
        view.addSubview(button)
    }

    @objc
    private func tapAuthButton() {
//        present(authUI.authViewController(), animated: true)
    }
}
