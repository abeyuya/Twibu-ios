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

        UserDispatcher.linkTwitterAccount(session: session) { [weak self] result in
            switch result {
            case .success(_):
                self?.showAlert(title: "Success", message: "Twitter連携しました！")
                self?.delegate?.reload(item: self?.item)
            case .failure(let error):
                self?.showAlert(title: "Error", message: error.displayMessage)
            }
        }
    }
}
