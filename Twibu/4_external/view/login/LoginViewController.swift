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
    @IBOutlet private weak var twitterButton: UIButton! {
        didSet {
            twitterButton.addTarget(self, action: #selector(tapLogin), for: .touchUpInside)
            twitterButton.layer.cornerRadius = 4
            twitterButton.setIcon(
                prefixText: "",
                prefixTextColor: .clear,
                icon: .fontAwesomeBrands(.twitter),
                iconColor: .white,
                postfixText: "  Twitter連携する",
                postfixTextColor: .white,
                backgroundColor: .twitter,
                forState: .normal,
                textSize: nil,
                iconSize: nil
            )
        }
    }

    var item: PagingIndexItem?
    weak var delegate: PagingRootViewControllerDelegate?
    private var currentUser: TwibuUser?

    @IBOutlet private weak var stackView: UIStackView!

    override func viewDidLoad() {
        super.viewDidLoad()
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
