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
import Parchment

final class LoginViewController: UIViewController {

    var item: PagingIndexItem?
    weak var delegate: PagingRootViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        let button = buildLoginButton()
        button.center = view.center
        view.addSubview(button)
    }

    private func buildLoginButton() -> UIView {
        let loginButton = TWTRLogInButton() { [weak self] session, error in
            guard let session = session else {
                let message = error?.localizedDescription ?? "ログインに失敗しました"
                self?.showAlert(title: "Error", message: message)
                return
            }

            let cred = TwitterAuthProvider.credential(
                withToken: session.authToken,
                secret: session.authTokenSecret
            )

            Auth.auth().signIn(with: cred) { result, error in
                if let error = error {
                    self?.showAlert(title: "Error", message: error.localizedDescription)
                    return
                }
                guard let result = result else {
                    self?.showAlert(title: "Error", message: "ログインユーザが取得できませんでした")
                    return
                }

                User.add(
                    uid: result.user.uid,
                    userName: session.userName,
                    userId: session.userID,
                    accessToken: session.authToken,
                    secretToken: session.authTokenSecret
                ) { result in
                    switch result {
                    case .success:
                        self?.delegate?.reload(item: self?.item)
                    case .failure(let error):
                        self?.showAlert(title: "Error", message: error.localizedDescription)
                    }
                }
            }
        }

        return loginButton
    }

    private func showAlert(title: String?, message: String) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        let okAction = UIAlertAction(title: "OK", style: .cancel)
        alert.addAction(okAction)
        present(alert, animated: true)
    }
}
