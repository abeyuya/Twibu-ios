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
import Embedded

protocol PagingRootViewControllerDelegate: class {
    func reload(item: PagingIndexItem?)
}

final class PagingRootViewController: UIViewController, StoryboardInstantiatable {
    private let pagingViewController = PagingViewController<PagingIndexItem>()
    private var currentUser: TwibuUser?

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
        super.viewWillDisappear(animated)
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
//        pagingViewController.delegate = self
        pagingViewController.menuItemSize = .sizeToFit(minWidth: 120, height: 40)
        pagingViewController.indicatorColor = .mainBlack
        pagingViewController.textColor = .tabUnselectGray
        pagingViewController.selectedTextColor = .mainBlack
        pagingViewController.selectedBackgroundColor = .tabBgGray
        pagingViewController.backgroundColor = .tabBgGray
        pagingViewController.borderOptions = .hidden

        let c = Category.all
        let i = PagingRootViewController.getIndex(c: c)
        pagingViewController.select(pagingItem: PagingIndexItem(index: i, title: c.displayString))
    }

    private func setupNavigation() {
        let b = UIButton()
        b.setIcon(icon: .fontAwesomeSolid(.cog), forState: .normal)
        b.addTarget(self, action: #selector(tapMenuButton), for: .touchUpInside)
        let bb = UIBarButtonItem(customView: b)
        navigationItem.setLeftBarButton(bb, animated: false)

        let iconView: UIImageView = {
            let icon = UIImage(named: "app_icon_29")
            let iv = UIImageView(image: icon)
            iv.contentMode = .scaleAspectFit
            iv.frame.size = CGSize(width: 29, height: 29)
            iv.clipsToBounds = true
            iv.layer.cornerRadius = 6
            iv.layer.borderWidth = 0.5
            iv.layer.borderColor = UIColor.lightGray.cgColor
            return iv
        }()
        navigationItem.titleView = iconView

        let backButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = backButtonItem
    }

    @objc
    private func tapMenuButton() {
        let vc = SettingsViewController.initFromStoryBoard()
        vc.delegate = self
        let nav = UINavigationController(rootViewController: vc)
        present(nav, animated: true)
    }
}

extension PagingRootViewController {
    private static let tabCategories: [Embedded.Category] = [
        .timeline,
        .all,
        .social,
        .economics,
        .life,
        .knowledge,
        .it,
        .fun,
        .entertainment,
        .game
    ]

    static func getIndex(c: Embedded.Category) -> Int {
        return PagingRootViewController.tabCategories.firstIndex(of: c)!
    }

    static func getCategory(index: Int) -> Embedded.Category {
        return PagingRootViewController.tabCategories[index]
    }

    static func calcLogicalIndex(physicalIndex: Int) -> Int {
        let i = physicalIndex % PagingRootViewController.tabCategories.count

        if i >= 0 {
            return i
        }

        return i + PagingRootViewController.tabCategories.count
    }
}

extension PagingRootViewController: PagingViewControllerInfiniteDataSource {
    func pagingViewController<T>(_ pagingViewController: PagingViewController<T>, viewControllerForPagingItem pagingItem: T) -> UIViewController {
        guard let item = pagingItem as? PagingIndexItem else {
            return UIViewController()
        }

        let i = PagingRootViewController.calcLogicalIndex(physicalIndex: item.index)
        let category = PagingRootViewController.getCategory(index: i)

        switch category {
        case .timeline:
            guard let isLogin = currentUser?.isTwitterLogin, isLogin else {
                let vc = LoginViewController.initFromStoryBoard()
                vc.item = item
                vc.delegate = self
                return vc
            }

            let vc = CategoryViewController.initFromStoryBoard()
            let vm = CategoryArticleListViewModel()
            vm.set(delegate: vc, type: .category(.timeline))
            vc.set(vm: vm)
            return vc

        case .all, .economics, .entertainment, .fun, .game, .it, .knowledge, .social, .life:
            let vc = CategoryViewController.initFromStoryBoard()
            let vm = CategoryArticleListViewModel()
            vm.set(delegate: vc, type: .category(category))
            vc.set(vm: vm)
            return vc

        case .memo, .unknown:
            assertionFailure("通らないはず")
            return UIViewController()
        }
    }

    func pagingViewController<T>(_ pagingViewController: PagingViewController<T>, pagingItemBeforePagingItem pagingItem: T) -> T? {
        guard let currentItem = pagingItem as? PagingIndexItem else { return nil }
        let categoryIndex = PagingRootViewController.calcLogicalIndex(physicalIndex: currentItem.index - 1)
        let category = PagingRootViewController.getCategory(index: categoryIndex)
        return PagingIndexItem(index: currentItem.index - 1, title: category.displayString) as? T
    }

    func pagingViewController<T>(_ pagingViewController: PagingViewController<T>, pagingItemAfterPagingItem pagingItem: T) -> T? {
        guard let currentItem = pagingItem as? PagingIndexItem else { return nil }
        let categoryIndex = PagingRootViewController.calcLogicalIndex(physicalIndex: currentItem.index + 1)
        let category = PagingRootViewController.getCategory(index: categoryIndex)
        return PagingIndexItem(index: currentItem.index + 1, title: category.displayString) as? T
    }
}

extension PagingRootViewController: PagingViewControllerDelegate {
//    func pagingViewController<T: PagingItem>(_ pagingViewController: PagingViewController<T>, widthForPagingItem pagingItem: T, isSelected: Bool) -> CGFloat? where T : PagingItem, T : Comparable, T : Hashable {
//
//        guard let currentItem = pagingItem as? PagingIndexItem else { return nil }
//        let categoryIndex = Category.calcLogicalIndex(physicalIndex: currentItem.index)
//        guard let category = Category(index: categoryIndex) else { return nil }
//        return 150
//    }
}

extension PagingRootViewController: StoreSubscriber {
    typealias StoreSubscriberStateType = TwibuUser?

    func newState(state: TwibuUser?) {
        currentUser = state
    }
}

extension PagingRootViewController: PagingRootViewControllerDelegate {
    func reload(item: PagingIndexItem?) {
        DispatchQueue.main.async {
            if let item = item {
                self.pagingViewController.reloadData(around: item)
            } else {
                let c = Category.all
                let i = PagingRootViewController.getIndex(c: c)
                self.pagingViewController.select(pagingItem: PagingIndexItem(index: i, title: c.displayString))
            }
        }
    }
}
