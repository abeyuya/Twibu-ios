//
//  SettingsViewController.swift
//  Twibu
//
//  Created by abeyuya on 2019/07/02.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import UIKit
import FirebaseAuth

final class SettingsViewController: UIViewController, StoryboardInstantiatable {

    @IBOutlet weak var tableView: UITableView!

    private enum Menu: String, CaseIterable {
        case term = "利用規約"
        case privacyPolicy = "プライバシーポリシー"
        case licence = "ライセンス"
        case logout = "ログアウト"
        case version = "バージョン"
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupTableview()
        setupNavigation()
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
        let alert = UIAlertController(
            title: "",
            message: "ログアウトしますか？",
            preferredStyle: .alert
        )
        let okAction = UIAlertAction(title: "Logout", style: .destructive) { _ in
            guard let user = Auth.auth().currentUser else {
                self.showAlert(title: "Error", message: TwibuError.needFirebaseAuth("ログアウトしようとした").displayMessage)
                return
            }

            user.unlink(fromProvider: "twitter.com") { [weak self] user, error in
                if let error = error {
                    self?.showAlert(title: "Error", message: TwibuError.signOut(error.localizedDescription).displayMessage)
                    return
                }

                // TODO: access_tokenとか使えなくなるので消したい
                // self?.delegate?.reload(item: self?.item)
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
        let cell = UITableViewCell()
        cell.textLabel?.text = Menu.allCases[indexPath.row].rawValue
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
