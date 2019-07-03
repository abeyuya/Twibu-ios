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

final class SettingsViewController: UIViewController, StoryboardInstantiatable {

    @IBOutlet weak var tableView: UITableView!

    private var currentUser: TwibuUser?
    weak var delegate: PagingRootViewControllerDelegate?

    private enum Menu: String, CaseIterable {
        case term = "利用規約"
        case privacyPolicy = "プライバシーポリシー"
        case licence = "ライセンス"
        case logout = "Twitter連携を取り消す"
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

    private func tapLogout() {
        if currentUser?.isTwitterLogin == false {
            return
        }

        let alert = UIAlertController(
            title: "",
            message: "Twitter連携を解除しますか？",
            preferredStyle: .alert
        )

        let okAction = UIAlertAction(title: "Logout", style: .destructive) { _ in
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
                        self?.showAlert(title: "Success", message: "Twitterからログアウトしました")
                        self?.delegate?.reload(item: nil)
                    }
                }
            }
        }

        let cancelAction = UIAlertAction(title: "cancel", style: .cancel)
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        present(alert, animated: true)
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
        case .licence, .privacyPolicy, .term:
            cell.textLabel?.text = menu.rawValue
            cell.accessoryType = .disclosureIndicator
        case .version:
            cell.textLabel?.text = menu.rawValue
            cell.detailTextLabel?.text = "\(Const.version) (\(Const.build))"
        case .logout:
            cell.textLabel?.text = menu.rawValue
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

            if currentUser?.isTwitterLogin == true {
            } else {
                cell.textLabel?.textColor = .lightGray
            }
        }
        return cell
    }
}

extension SettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let menu = Menu.allCases[indexPath.row]

        switch menu {
        case .logout: tapLogout()
        case .term: break
        case .privacyPolicy: break
        case .licence: break
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