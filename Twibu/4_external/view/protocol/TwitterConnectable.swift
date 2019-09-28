//
//  TwitterConnectable.swift
//  Twibu
//
//  Created by abeyuya on 2019/09/27.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import UIKit
import SafariServices

import Swifter
import Crashlytics
import FirebaseAuth
import Embedded

protocol TwitterConnectable: SFSafariViewControllerDelegate {
    func didTwitterConnectSuccess()
    func didTwitterUnlinkSuccess()
}

extension TwitterConnectable where Self: UIViewController {
    internal func startTwitterLink(currentUser: TwibuUser) {
        guard let url = URL(string: Const.twitterCallbackUrlProtocol + "://") else { return }
        AnalyticsDispatcer.logging(.loginTry, param: ["method": "twitter"])
        let s = Swifter(consumerKey: Const.twitterConsumerKey, consumerSecret: Const.twitterConsumerSecret)
        s.authorize(
            withCallback: url,
            presentingFrom: self,
            success: { loginResult, _ in
                self.performLoginSuccess(loginResult: loginResult, currentUser: currentUser)
            },
            failure: { error in
                self.showAlert(
                    title: "Error",
                    message: TwibuError.twitterLogin(error.localizedDescription).displayMessage
                )
            }
        )
    }

    private func performLoginSuccess(loginResult: Credential.OAuthAccessToken?, currentUser: TwibuUser) {
        guard let firebaseUser = currentUser.firebaseAuthUser else {
            let e = TwibuError.needFirebaseAuth("firebase匿名ログインもできてない")
            self.showAlert(title: "Error", message: e.displayMessage)
            Logger.print(e)
            Crashlytics.sharedInstance().recordError(e)
            return
        }

        guard let loginResult = loginResult else {
            self.showAlert(
                title: "Error",
                message: TwibuError.twitterLogin("sessionがnil").displayMessage
            )
            return
        }

        performLinkTwitter(firebaseUser: firebaseUser, loginResult: loginResult)
    }

    private func performLinkTwitter(firebaseUser: User, loginResult: Credential.OAuthAccessToken) {
        UserDispatcher.linkTwitterAccount(firebaseUser: firebaseUser, session: loginResult) { [weak self] result in
            switch result {
            case .success(_):
                self?.showAlert(title: "Success", message: "Twitter連携しました！")
                self?.didTwitterConnectSuccess()
                AnalyticsDispatcer.logging(.login, param: ["method": "twitter"])
            case .failure(let error):
                switch error {
                case .twitterLoginAlreadyExist(_):
                    self?.showUserSwitchConfirm(firebaseUser: firebaseUser, loginResult: loginResult)
                default:
                    self?.showAlert(title: "Error", message: error.displayMessage)
                    Logger.print(error)
                    Crashlytics.sharedInstance().recordError(error)
                }
            }
        }
    }

    private func performLoginAsTwitter(firebaseUser: User, loginResult: Credential.OAuthAccessToken) {
        UserDispatcher.loginAsTwitterAccount(anonymousFirebaseUser: firebaseUser, session: loginResult) { [weak self] result in
            switch result {
            case .success(_):
                self?.showAlert(title: "Success", message: "Twitter連携しました！")
                self?.didTwitterConnectSuccess()
                AnalyticsDispatcer.logging(.login, param: ["method": "twitter"])
            case .failure(let error):
                self?.showAlert(title: "Error", message: error.displayMessage)
                Logger.print(error)
                Crashlytics.sharedInstance().recordError(error)
            }
        }
    }

    private func showUserSwitchConfirm(firebaseUser: User, loginResult: Credential.OAuthAccessToken) {
        let alert = UIAlertController(
            title: nil,
            message: "このTwitterアカウントは既に利用されています。連携してもよろしいですか？(現在の「メモ」は破棄されます)",
            preferredStyle: .alert
        )

        let ok = UIAlertAction(title: "連携する", style: .destructive) { _ in
            self.performLoginAsTwitter(firebaseUser: firebaseUser, loginResult: loginResult)
        }
        let cancel = UIAlertAction(title: "キャンセル", style: .default)

        alert.addAction(cancel)
        alert.addAction(ok)
        present(alert, animated: true)
    }

    internal func startTwitterUnlink(currentUser: TwibuUser) {
        if currentUser.isTwitterLogin == false {
            return
        }

        AnalyticsDispatcer.logging(
            .logoutTry,
            param: ["method": "twitter"]
        )

        let alert = UIAlertController(
            title: "",
            message: "Twitter連携を解除しますか？",
            preferredStyle: .alert
        )

        let logoutAction = UIAlertAction(title: "解除する", style: .destructive) { _ in
            guard let user = Auth.auth().currentUser else {
                self.showAlert(
                    title: "Error",
                    message: TwibuError.needFirebaseAuth("ログアウトしようとした").displayMessage
                )
                return
            }

            UserDispatcher.unlinkTwitter(firebaseUser: user) { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .failure(let error):
                        self?.showAlert(title: "Error", message: error.displayMessage)
                    case .success(_):
                        self?.showAlert(title: "Success", message: "Twitterからログアウトしました")
                        self?.didTwitterUnlinkSuccess()
                        AnalyticsDispatcer.logging(
                            .logout,
                            param: ["method": "twitter"]
                        )
                    }
                }
            }
        }

        let cancelAction = UIAlertAction(title: "キャンセル", style: .default)
        alert.addAction(cancelAction)
        alert.addAction(logoutAction)
        present(alert, animated: true)
    }
}
