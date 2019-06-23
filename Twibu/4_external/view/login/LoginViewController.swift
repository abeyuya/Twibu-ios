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

final class LoginViewController: UIViewController, StoryboardInstantiatable {

    var item: PagingIndexItem?
    weak var delegate: PagingRootViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        let button = buildLoginButton()
        button.center = view.center
        view.addSubview(button)
    }

    private func buildLoginButton() -> UIView {
        let loginButton = TWTRLogInButton(logInCompletion: buildLoginCompletion)
        return loginButton
    }

    private func buildLoginCompletion(session: TWTRSession?, error: Error?) {
        if let error = error {
            self.showAlert(
                title: "Error",
                message: TwibuError.twitterLogin(error.localizedDescription).displayMessage
            )
            return
        }

        guard let session = session else {
            self.showAlert(
                title: "Error",
                message: TwibuError.twitterLogin("sessionがnil").displayMessage
            )
            return
        }

        linkTwitterAccount(session: session)
    }

    private func linkTwitterAccount(session: TWTRSession) {
        guard let user = Auth.auth().currentUser else {
            self.showAlert(title: "Error", message: TwibuError.needFirebaseAuth(nil).displayMessage)
            return
        }

        let cred = TwitterAuthProvider.credential(
            withToken: session.authToken,
            secret: session.authTokenSecret
        )

        user.link(with: cred) { [weak self] result, error in
            if let error = error {
                self?.showAlert(
                    title: "Error",
                    message: TwibuError.twitterLogin(error.localizedDescription).displayMessage
                )
                return
            }
            guard let result = result else {
                self?.showAlert(
                    title: "Error",
                    message: TwibuError.twitterLogin("Twitterユーザが取得できませんでした").displayMessage
                )
                return
            }

            UserRepository.add(
                uid: result.user.uid,
                userName: session.userName,
                userId: session.userID,
                accessToken: session.authToken,
                secretToken: session.authTokenSecret
            ) { [weak self] result in
                switch result {
                case .success:
                    self?.delegate?.reload(item: self?.item)
                case .failure(let error):
                    self?.showAlert(title: "Error", message: error.displayMessage)
                }
            }
        }
    }
}
