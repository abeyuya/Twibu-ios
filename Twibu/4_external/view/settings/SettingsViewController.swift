//
//  SettingsViewController.swift
//  Twibu
//
//  Created by abeyuya on 2019/07/02.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import UIKit
import SafariServices

import FirebaseAuth
import ReSwift
import Crashlytics
import Swifter
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

        performLinkTwitter(firebaseUser: firebaseUser, session: session)
    }

    private func performLinkTwitter(firebaseUser: User, session: Credential.OAuthAccessToken) {
        UserDispatcher.linkTwitterAccount(firebaseUser: firebaseUser, session: session) { [weak self] result in
            switch result {
            case .success(_):
                self?.showAlert(title: "Success", message: "Twitter連携しました！")
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
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
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
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
        let cancel = UIAlertAction(title: "キャンセル", style: .default)

        alert.addAction(cancel)
        alert.addAction(ok)
        present(alert, animated: true)
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

        let cancelAction = UIAlertAction(title: "キャンセル", style: .default)
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
            url: url,
            category: .unknown
        )
        vc.set(bookmark: b)
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
            let vm = CategoryArticleListViewModel()
            vm.set(delegate: vc, type: .category(.memo))
            vc.set(vm: vm)
            BookmarkDispatcher.fetchBookmark(
                category: .memo,
                uid: uid,
                type: .new(limit: 30),
                commentCountOffset: 0
            ) { _ in }
            navigationController?.pushViewController(vc, animated: true)
        case .history:
            HistoryDispatcher.fetchHistory(offset: 0)
            let vc = CategoryViewController.initFromStoryBoard()
            let vm = HistoryArticleListViewModel()
            vm.set(delegate: vc, type: .history)
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
            case .debug:
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
        }
    }
}

extension SettingsViewController: StoreSubscriber {
    typealias StoreSubscriberStateType = TwibuUser

    func newState(state: TwibuUser) {
        currentUser = state
    }
}

extension SettingsViewController: SFSafariViewControllerDelegate {}
