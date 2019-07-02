//
//  PagingViewController.swift
//  Twibu
//
//  Created by abeyuya on 2019/06/16.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import UIKit
import FirebaseAuth
import Parchment
import ReSwift

final class PagingRootViewController: UIViewController, StoryboardInstantiatable {

    private let pagingViewController = PagingViewController<PagingIndexItem>()

    override func viewDidLoad() {
        super.viewDidLoad()

        setupPagingView()
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
        store.unsubscribe(self)
    }

    private func setupPagingView() {
        addChild(pagingViewController)
        view.addSubview(pagingViewController.view)
        pagingViewController.view.translatesAutoresizingMaskIntoConstraints = false
        pagingViewController.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        pagingViewController.view.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        pagingViewController.view.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        pagingViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        pagingViewController.didMove(toParent: self)

        pagingViewController.infiniteDataSource = self
        pagingViewController.delegate = self
        pagingViewController.menuItemSize = .sizeToFit(minWidth: 120, height: 40)
        pagingViewController.textColor = .tabUnselectGray
        pagingViewController.selectedTextColor = .mainBlack
        pagingViewController.indicatorColor = .mainBlack
        pagingViewController.backgroundColor = .tabBgGray
        pagingViewController.menuBackgroundColor = .tabBgGray
        pagingViewController.borderOptions = .hidden

        let c = Category.all
        pagingViewController.select(pagingItem: PagingIndexItem(index: c.index, title: c.displayString))
    }

    private func setupNavigation() {
        title = "ホーム"

        let b = UIButton()
        b.setIcon(icon: .fontAwesomeSolid(.cog), forState: .normal)
        b.addTarget(self, action: #selector(tapMenuButton), for: .touchUpInside)
        let bb = UIBarButtonItem(customView: b)
        navigationItem.setLeftBarButton(bb, animated: false)
    }

    @objc
    private func tapMenuButton() {
        let vc = SettingsViewController.initFromStoryBoard()
        let nav = UINavigationController(rootViewController: vc)
        present(nav, animated: true)
    }
}

extension PagingRootViewController: PagingViewControllerInfiniteDataSource {
    func pagingViewController<T>(_ pagingViewController: PagingViewController<T>, viewControllerForPagingItem pagingItem: T) -> UIViewController {
        guard let item = pagingItem as? PagingIndexItem else {
            return UIViewController()
        }

        let i = Category.calcLogicalIndex(physicalIndex: item.index)
        guard let category = Category(index: i) else {
            return UIViewController()
        }

        switch category {
        case .timeline:
            guard UserRepository.isTwitterLogin() else {
                let vc = LoginViewController.initFromStoryBoard()
                vc.item = item
                return vc
            }

            let vc = CategoryViewController.initFromStoryBoard()
            vc.item = item
            return vc

        case .all, .economics, .entertainment, .fun, .game, .general, .it, .knowledge, .social, .life:
            let vc = CategoryViewController.initFromStoryBoard()
            vc.item = item
            return vc
        }
    }

    func pagingViewController<T>(_ pagingViewController: PagingViewController<T>, pagingItemBeforePagingItem pagingItem: T) -> T? {
        guard let currentItem = pagingItem as? PagingIndexItem else { return nil }
        let categoryIndex = Category.calcLogicalIndex(physicalIndex: currentItem.index - 1)
        guard let category = Category(index: categoryIndex) else { return nil }
        return PagingIndexItem(index: currentItem.index - 1, title: category.displayString) as? T
    }

    func pagingViewController<T>(_ pagingViewController: PagingViewController<T>, pagingItemAfterPagingItem pagingItem: T) -> T? {
        guard let currentItem = pagingItem as? PagingIndexItem else { return nil }
        let categoryIndex = Category.calcLogicalIndex(physicalIndex: currentItem.index + 1)
        guard let category = Category(index: categoryIndex) else { return nil }
        return PagingIndexItem(index: currentItem.index + 1, title: category.displayString) as? T
    }
}

extension PagingRootViewController: PagingViewControllerDelegate {}

extension PagingRootViewController: StoreSubscriber {
    typealias StoreSubscriberStateType = User?

    func newState(state: User?) {
        let timeline = pagingViewController.visibleItems.items.first { $0.title == Category.timeline.displayString }
        guard let t = timeline else { return }

        DispatchQueue.main.async {
            self.pagingViewController.reloadData(around: t)
        }
    }
}
