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
import Crashlytics
import Embedded

final class LoginViewController: UIViewController, StoryboardInstantiatable {

    var item: PagingIndexItem?
    weak var delegate: PagingRootViewControllerDelegate?
    private var currentUser: TwibuUser?

    @IBOutlet private weak var stackView: UIStackView!

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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if self.currentUser?.isTwitterLogin == true, let d = delegate {
            DispatchQueue.main.async {
                let indicator = UIActivityIndicatorView(style: .gray)
                indicator.startAnimating()
                self.stackView.addArrangedSubview(indicator)

                d.reload(item: self.item)
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        store.unsubscribe(self)
    }

    private func buildLoginButton() -> UIView {
        let loginButton = TWTRLogInButton(logInCompletion: buildLoginCompletion)
        loginButton.frame.size = CGSize(width: 240, height: 40)
        return loginButton
    }

    private func buildLoginCompletion(session: TWTRSession?, error: Error?) {
        AnalyticsDispatcer.logging(.loginTry, param: ["method": "twitter"])

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
            Logger.print(e)
            Crashlytics.sharedInstance().recordError(e)
            return
        }

        guard let session = session else {
            self.showAlert(
                title: "Error",
                message: TwibuError.twitterLogin("sessionがnil").displayMessage
            )
            return
        }

        let indicator = UIActivityIndicatorView(style: .gray)
        indicator.startAnimating()
        stackView.addArrangedSubview(indicator)

        UserDispatcher.linkTwitterAccount(user: firebaseUser, session: session) { [weak self] result in
            switch result {
            case .success(_):
                self?.showAlert(title: "Success", message: "Twitter連携しました！")
                self?.delegate?.reload(item: self?.item)
                AnalyticsDispatcer.logging(.login, param: ["method": "twitter"])
            case .failure(let error):
                self?.showAlert(title: "Error", message: error.displayMessage)
                Logger.print(error)
                Crashlytics.sharedInstance().recordError(error)
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
