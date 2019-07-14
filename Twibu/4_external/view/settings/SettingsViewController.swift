//
//  SettingsViewController.swift
//  Twibu
//
//  Created by abeyuya on 2019/07/02.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import UIKit
import FirebaseAuth
import ReSwift
import TwitterKit

final class SettingsViewController: UIViewController, StoryboardInstantiatable {

    @IBOutlet weak var tableView: UITableView!

    private var currentUser: TwibuUser?
    weak var delegate: PagingRootViewControllerDelegate?

    private enum Menu: String, CaseIterable {
        case term = "利用規約"
        case privacyPolicy = "プライバシーポリシー"
        case twitter = "Twitter連携"
        case version = "バージョン"
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupTableview()
        setupNavigation()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        store.subscribe(self) { subcription in
            subcription.select { state in
                return state.currentUser
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        store.unsubscribe(self)
    }

    private func setupTableview() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
    }

    private func setupNavigation() {
        title = "設定"

        let b = UIButton()
        b.setIcon(icon: .linearIcons(.cross), forState: .normal)
        b.addTarget(self, action: #selector(tapMenuButton), for: .touchUpInside)
        let bb = UIBarButtonItem(customView: b)
        navigationItem.setLeftBarButton(bb, animated: false)
    }

    @objc
    private func tapMenuButton() {
        dismiss(animated: true)
    }

    private func tapLogin() {
        TWTRTwitter.sharedInstance().logIn { (session, error) in
            AnalyticsDispatcer.logging(.loginTry, param: ["method": "twitter"])

            if let error = error {
                self.showAlert(
                    title: "Error",
                    message: TwibuError.twitterLogin(error.localizedDescription).displayMessage
                )
                return
            }

            guard let firebaseUser = self.currentUser?.firebaseAuthUser else {
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
                    DispatchQueue.main.async {
                        self?.tableView.reloadData()
                    }
                    AnalyticsDispatcer.logging(.login, param: ["method": "twitter"])
                case .failure(let error):
                    self?.showAlert(title: "Error", message: error.displayMessage)
                    Logger.log(error)
                }
            }
        }
    }

    private func tapLogout() {
        AnalyticsDispatcer.logging(
            .logoutTry,
            param: ["method": "twitter"]
        )

        if currentUser?.isTwitterLogin == false {
            return
        }

        let alert = UIAlertController(
            title: "",
            message: "Twitter連携を解除しますか？",
            preferredStyle: .alert
        )

        let logoutAction = UIAlertAction(title: "Logout", style: .destructive) { _ in
            guard let user = Auth.auth().currentUser else {
                self.showAlert(title: "Error", message: TwibuError.needFirebaseAuth("ログアウトしようとした").displayMessage)
                return
            }

            UserDispatcher.unlinkTwitter(user: user) { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .failure(let error):
                        self?.showAlert(title: "Error", message: error.displayMessage)
                    case .success(_):
                        self?.tableView.reloadData()
                        self?.showAlert(title: "Success", message: "Twitterからログアウトしました")
                        self?.delegate?.reload(item: nil)

                        AnalyticsDispatcer.logging(
                            .logout,
                            param: ["method": "twitter"]
                        )
                    }
                }
            }
        }

        let cancelAction = UIAlertAction(title: "cancel", style: .default)
        alert.addAction(cancelAction)
        alert.addAction(logoutAction)
        present(alert, animated: true)
    }

    private func openWebView(title: String, url: String) {
        let vc = WebViewController.initFromStoryBoard()
        let b = Bookmark(
            uid: "",
            title: title,
            image_url: nil,
            description: nil,
            comment_count: nil,
            created_at: nil,
            updated_at: nil,
            url: url
        )
        vc.set(bookmark: b)
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension SettingsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Menu.allCases.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let menu = Menu.allCases[indexPath.row]
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "Cell")

        switch menu {
        case .privacyPolicy, .term:
            cell.textLabel?.text = menu.rawValue
            cell.accessoryType = .disclosureIndicator
        case .version:
            cell.textLabel?.text = menu.rawValue
            cell.detailTextLabel?.text = "\(Const.version) (\(Const.build))"
        case .twitter:
            cell.textLabel?.text = currentUser?.isTwitterLogin == true
                ? "Twitter連携を取り消す"
                : "Twitter連携する"

            cell.detailTextLabel?.setIcon(
                prefixText: "",
                prefixTextColor: .clear,
                icon: .fontAwesomeBrands(.twitter),
                iconColor: currentUser?.isTwitterLogin == true ? .twitter : .lightGray,
                postfixText: "",
                postfixTextColor: .clear,
                size: 17,
                iconSize: 17
            )
        }
        return cell
    }
}

extension SettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let menu = Menu.allCases[indexPath.row]

        switch menu {
        case .twitter:
            currentUser?.isTwitterLogin == true ? tapLogout() : tapLogin()
        case .term:
            openWebView(title: menu.rawValue, url: "https://github.com/abeyuya")
        case .privacyPolicy:
            openWebView(title: menu.rawValue, url: "https://github.com/sikmi")
        case .version:
            break
        }
    }
}

extension SettingsViewController: StoreSubscriber {
    typealias StoreSubscriberStateType = TwibuUser

    func newState(state: TwibuUser) {
        currentUser = state
    }
}
