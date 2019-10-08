//
//  SettingsViewController.swift
//  Twibu
//
//  Created by abeyuya on 2019/07/02.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import UIKit

import ReSwift
import Embedded

final class SettingsViewController: UIViewController, StoryboardInstantiatable {
    @IBOutlet private weak var tableView: UITableView! {
        didSet {
            tableView.delegate = self
            tableView.dataSource = self
            tableView.tableFooterView = UIView()
        }
    }

    private var currentUser: TwibuUser?
    weak var delegate: PagingRootViewControllerDelegate?

    private enum Menu1: String, CaseIterable {
        case memo = "メモ"
        case history = "履歴"
        case twitter = "Twitter連携"
    }

    private enum Menu2: String, CaseIterable {
//        case term = "利用規約"
        case privacyPolicy = "プライバシーポリシー"
        case license = "ライセンス"
        case version = "バージョン"
    }

    override func viewDidLoad() {
        super.viewDidLoad()
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

    private func setupNavigation() {
        title = "設定"
        let bb = UIBarButtonItem.init(barButtonSystemItem: .stop, target: self, action: #selector(tapMenuButton))
        navigationItem.setRightBarButton(bb, animated: false)
    }

    @objc
    private func tapMenuButton() {
        dismiss(animated: true)
    }

    private func tapLogin() {
        guard let u = currentUser else {
            showAlert(
                title: nil,
                message: TwibuError.needFirebaseAuth("何故かログインユーザがとれてない").displayMessage
            )
            return
        }
        startTwitterLink(currentUser: u)
    }

    private func tapLogout() {
        guard let u = currentUser else {
            showAlert(
                title: nil,
                message: TwibuError.needFirebaseAuth("何故かログインユーザがとれてない").displayMessage
            )
            return
        }
        startTwitterUnlink(currentUser: u)
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
            url: url,
            category: .unknown
        )
        let vm = WebViewModel(bookmark: b, delegate: vc)
        vc.set(viewModel: vm)
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension SettingsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return Menu1.allCases.count
        case 1:
            return Menu2.allCases.count
        default:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            return setupMenu1Cell(index: indexPath.row)
        case 1:
            return setupMenu2Cell(index: indexPath.row)
        default:
            return UITableViewCell()
        }
    }

    private func setupMenu1Cell(index: Int) -> UITableViewCell {
        let menu = Menu1.allCases[index]
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "Cell")

        switch menu {
        case .memo, .history:
            cell.textLabel?.text = menu.rawValue
            cell.accessoryType = .disclosureIndicator
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

    private func setupMenu2Cell(index: Int) -> UITableViewCell {
        let menu = Menu2.allCases[index]
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "Cell")

        switch menu {
        case .privacyPolicy:
            cell.textLabel?.text = menu.rawValue
            cell.accessoryType = .disclosureIndicator
        case .version:
            cell.textLabel?.text = menu.rawValue
            cell.detailTextLabel?.text = "\(Const.version) (\(Const.build))"
        case .license:
            cell.textLabel?.text = menu.rawValue
            cell.accessoryType = .detailButton
        }
        return cell
    }
}

extension SettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch indexPath.section {
        case 0:
            didSelectMenu1(index: indexPath.row)
        case 1:
            didSelectMenu2(index: indexPath.row)
        default:
            break
        }
    }

    private func didSelectMenu1(index: Int) {
        guard let uid = currentUser?.firebaseAuthUser?.uid else { return }
        let menu = Menu1.allCases[index]

        switch menu {
        case .memo:
            let vc = CategoryViewController.initFromStoryBoard()
            let vm = MemoArticleListViewModel(delegate: vc, type: .memo)
            vc.set(vm: vm)
            MemoDispatcher.fetchMemos(userUid: uid, type: .new(limit: 30))
            navigationController?.pushViewController(vc, animated: true)
        case .history:
            HistoryDispatcher.fetchHistory(offset: 0)
            let vc = CategoryViewController.initFromStoryBoard()
            let vm = HistoryArticleListViewModel(delegate: vc, type: .history)
            vc.set(vm: vm)
            navigationController?.pushViewController(vc, animated: true)
        case .twitter:
            currentUser?.isTwitterLogin == true ? tapLogout() : tapLogin()
        }
    }

    private func didSelectMenu2(index: Int) {
        let menu = Menu2.allCases[index]

        switch menu {
//        case .term:
//            openWebView(title: menu.rawValue, url: "https://github.com/abeyuya")
        case .privacyPolicy:
            openWebView(title: menu.rawValue, url: "https://twibu-c4d5a.web.app/privacy_policy.html")
        case .version:
            switch Env.current {
            case .debug, .adhoc:
                let message: String = {
                    guard let u = currentUser else {
                        return "おかしい: ログインユーザが存在しません"
                    }

                    let twitterState: String = {
                        guard let fu = u.firebaseAuthUser else { return "してません" }
                        return TwibuUser.isTwitterLogin(user: fu) ? "してます" : "してません"
                    }()

                    return [
                        "uid: \(u.firebaseAuthUser?.uid ?? "no uid")",
                        "isTwitterLogin: \(twitterState)"
                    ].joined(separator: "\n")
                }()
                self.showAlert(title: "デバッグ情報", message: message)
            case .release:
                break
            }
        case .license:
            guard let url = URL(string: UIApplication.openSettingsURLString),
                UIApplication.shared.canOpenURL(url) else {
                    return
            }
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}

extension SettingsViewController: StoreSubscriber {
    typealias StoreSubscriberStateType = TwibuUser

    func newState(state: TwibuUser) {
        currentUser = state
    }
}

extension SettingsViewController: TwitterConnectable {
    func didTwitterConnectSuccess() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }

    func didTwitterUnlinkSuccess() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
            self.delegate?.reload(item: nil)
        }
    }
}
