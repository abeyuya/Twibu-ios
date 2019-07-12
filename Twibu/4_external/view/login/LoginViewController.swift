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
import ReSwift

final class LoginViewController: UIViewController, StoryboardInstantiatable {

    var item: PagingIndexItem?
    weak var delegate: PagingRootViewControllerDelegate?
    private var currentUser: TwibuUser?
    @IBOutlet weak var stackView: UIStackView!

    override func viewDidLoad() {
        super.viewDidLoad()

        let button = buildLoginButton()
        stackView.addArrangedSubview(button)

        store.subscribe(self) { subcription in
            subcription.select { state in
                return state.currentUser
            }
        }
    }

    private func buildLoginButton() -> UIView {
        let loginButton = TWTRLogInButton(logInCompletion: buildLoginCompletion)
        loginButton.frame.size = CGSize(width: 240, height: 40)
        return loginButton
    }

    private func buildLoginCompletion(session: TWTRSession?, error: Error?) {
        AnalyticsDispatcer.logging(.logoutTry, param: ["method": "twitter"])

        if let error = error {
            self.showAlert(
                title: "Error",
                message: TwibuError.twitterLogin(error.localizedDescription).displayMessage
            )
            return
        }

        guard let firebaseUser = currentUser?.firebaseAuthUser else {
            let e = TwibuError.needFirebaseAuth("firebase匿名ログインもできてない")
            self.showAlert(title: "Error", message: e.displayMessage)
            Logger.log(e)
            return
        }

        guard let session = session else {
            self.showAlert(
                title: "Error",
                message: TwibuError.twitterLogin("sessionがnil").displayMessage
            )
            return
        }

        UserDispatcher.linkTwitterAccount(user: firebaseUser, session: session) { [weak self] result in
            switch result {
            case .success(_):
                self?.showAlert(title: "Success", message: "Twitter連携しました！")
                self?.delegate?.reload(item: self?.item)
                AnalyticsDispatcer.logging(.login, param: ["method": "twitter"])
            case .failure(let error):
                self?.showAlert(title: "Error", message: error.displayMessage)
                Logger.log(error)
            }
        }
    }
}

extension LoginViewController: StoreSubscriber {
    typealias StoreSubscriberStateType = TwibuUser

    func newState(state: TwibuUser) {
        self.currentUser = state
    }
}
