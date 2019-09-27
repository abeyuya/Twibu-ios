//
//  ViewController.swift
//  Twibu
//
//  Created by abeyuya on 2019/06/15.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import UIKit
import SafariServices

import FirebaseAuth
import Parchment
import ReSwift
import Crashlytics
import Swifter
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

        guard let isTwitterLogin = self.currentUser?.isTwitterLogin, isTwitterLogin else {
            return
        }

        if let d = delegate {
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
        let loginButton = UIButton()
        loginButton.frame.size = CGSize(width: 240, height: 40)
        loginButton.setTitle("Twitterでログイン", for: .normal)
        loginButton.addTarget(self, action: #selector(tapLogin), for: .touchUpInside)
        return loginButton
    }

    @objc
    private func tapLogin() {
        guard let url = URL(string: Const.twitterCallbackUrlProtocol + "://") else { return }
        let s = Swifter(consumerKey: Const.twitterConsumerKey, consumerSecret: Const.twitterConsumerSecret)
        s.authorize(
            withCallback: url,
            presentingFrom: self,
            success: { result, _ in
                self.buildLoginCompletion(session: result)
            },
            failure: { error in
                self.showAlert(
                    title: "Error",
                    message: TwibuError.twitterLogin(error.localizedDescription).displayMessage
                )
            }
        )
    }

    private func buildLoginCompletion(session: Credential.OAuthAccessToken?) {
        AnalyticsDispatcer.logging(.loginTry, param: ["method": "twitter"])

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
        performLinkTwitter(firebaseUser: firebaseUser, session: session)
    }

    private func performLinkTwitter(firebaseUser: User, session: Credential.OAuthAccessToken) {
        UserDispatcher.linkTwitterAccount(firebaseUser: firebaseUser, session: session) { [weak self] result in
            switch result {
            case .success(_):
                self?.showAlert(title: "Success", message: "Twitter連携しました！")
                self?.delegate?.reload(item: self?.item)
                AnalyticsDispatcer.logging(.login, param: ["method": "twitter"])
            case .failure(let error):
                switch error {
                case .twitterLoginAlreadyExist(_):
                    self?.showUserSwitchConfirm(firebaseUser: firebaseUser, session: session)
                default:
                    self?.showAlert(title: "Error", message: error.displayMessage)
                    Logger.print(error)
                    Crashlytics.sharedInstance().recordError(error)
                }
            }
        }
    }

    private func performLoginAsTwitter(firebaseUser: User, session: Credential.OAuthAccessToken) {
        UserDispatcher.loginAsTwitterAccount(anonymousFirebaseUser: firebaseUser, session: session) { [weak self] result in
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

    private func showUserSwitchConfirm(firebaseUser: User, session: Credential.OAuthAccessToken) {
        let alert = UIAlertController(
            title: nil,
            message: "このTwitterアカウントは既に利用されています。連携してもよろしいですか？(現在の「メモ」は破棄されます)",
            preferredStyle: .alert
        )

        let ok = UIAlertAction(title: "連携する", style: .destructive) { _ in
            self.performLoginAsTwitter(firebaseUser: firebaseUser, session: session)
        }
        let cancel = UIAlertAction(title: "キャンセル", style: .default) { _ in }

        alert.addAction(cancel)
        alert.addAction(ok)
        present(alert, animated: true)
    }
}

extension LoginViewController: StoreSubscriber {
    typealias StoreSubscriberStateType = TwibuUser

    func newState(state: TwibuUser) {
        self.currentUser = state
    }
}

extension LoginViewController: SFSafariViewControllerDelegate {}
