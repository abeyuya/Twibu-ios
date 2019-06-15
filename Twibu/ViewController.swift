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

final class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let button = buildLoginButton()
        button.center = view.center
        view.addSubview(button)
    }

    private func buildLoginButton() -> UIView {
        let loginButton = TWTRLogInButton() { [weak self] session, error in
            guard let session = session else {
                var message = error?.localizedDescription ?? "ログインに失敗しました"
                if DeviceType.current == .simulator {
                    message += "\n 何故かシミュレータではTwitterログインできない..."
                }

                self?.showErrorMessage(message: message)
                return
            }

            let cred = TwitterAuthProvider.credential(
                withToken: session.authToken,
                secret: session.authTokenSecret
            )

            Auth.auth().signIn(with: cred) { result, error in
                if let error = error {
                    self?.showErrorMessage(message: error.localizedDescription)
                    return
                }
            }
        }

        return loginButton
    }

    private func showErrorMessage(message: String) {
        let alert = UIAlertController(
            title: "Error",
            message: message,
            preferredStyle: .alert
        )
        let okAction = UIAlertAction(title: "OK", style: .cancel)
        alert.addAction(okAction)
        present(alert, animated: true)
    }
}
