//
//  ViewController.swift
//  Twibu
//
//  Created by abeyuya on 2019/06/15.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import UIKit

import Parchment
import ReSwift
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

        guard let isTwitterLogin = self.currentUser?.isTwitterLogin,
            isTwitterLogin,
            let d = delegate else { return }

        DispatchQueue.main.async {
            let indicator = UIActivityIndicatorView(style: .gray)
            indicator.startAnimating()
            self.stackView.addArrangedSubview(indicator)
            d.reload(item: self.item)
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
        guard let u = currentUser else {
            showAlert(
                title: nil,
                message: TwibuError.needFirebaseAuth("何故かログインユーザがとれてない").displayMessage
            )
            return
        }
        startLogin(currentUser: u)
    }
}

extension LoginViewController: StoreSubscriber {
    typealias StoreSubscriberStateType = TwibuUser

    func newState(state: TwibuUser) {
        self.currentUser = state
    }
}

extension LoginViewController: TwitterConnectable {
    func didTwitterConnectSuccess() {
        delegate?.reload(item: item)
    }

    func didTwitterUnlinkSuccess() {
    }
}
