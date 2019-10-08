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
        pagingViewController.delegate = self
        pagingViewController.menuItemSize = .sizeToFit(minWidth: 120, height: 40)
        pagingViewController.indicatorColor = .mainTint
        pagingViewController.textColor = .tabUnselectGray
        pagingViewController.selectedTextColor = .mainTint
        pagingViewController.selectedBackgroundColor = .tabBgGray
        pagingViewController.backgroundColor = .tabBgGray
        pagingViewController.borderOptions = .hidden

        let tc = TabCategory.all
        let i = PagingRootViewController.getIndex(c: tc)
        pagingViewController.select(pagingItem: PagingIndexItem(index: i, title: tc.displayString))
    }

    private func setupNavigation() {
        let bb: UIBarButtonItem = {
            let b = UIButton()
            b.setIcon(
                icon: .fontAwesomeSolid(.cog),
                iconSize: nil,
                color: .mainTint,
                backgroundColor: .clear,
                forState: .normal
            )
            b.addTarget(self, action: #selector(tapMenuButton), for: .touchUpInside)
            return UIBarButtonItem(customView: b)
        }()
        navigationItem.setRightBarButton(bb, animated: false)

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
    enum TabCategory: CaseIterable {
        case timeline
        case all
        case social
        case economics
        case life
        case knowledge
        case it
        case fun
        case entertainment
        case game

        public var displayString: String {
            switch self {
            case .timeline: return "タイムライン"
            case .all: return "トップ"
            case .social: return "社会"
            case .economics: return "政治・経済"
            case .life: return "ライフスタイル"
            case .knowledge: return "ふむふむ"
            case .it: return "テクノロジー"
            case .fun: return "いろいろ"
            case .entertainment: return "芸能・スポーツ"
            case .game: return "アニメ・ゲーム"
            }
        }

        public var category: Embedded.Category {
            switch self {
            case .timeline:
                assertionFailure("来ないはず")
                return .unknown
            case .all: return .all
            case .social: return .social
            case .economics: return .economics
            case .life: return .life
            case .knowledge: return .knowledge
            case .it: return .it
            case .fun: return .fun
            case .entertainment: return .entertainment
            case .game: return .game
            }
        }
    }

    static func getIndex(c: TabCategory) -> Int {
        return TabCategory.allCases.firstIndex(of: c)!
    }

    static func getCategory(index: Int) -> TabCategory {
        return TabCategory.allCases[index]
    }

    static func calcLogicalIndex(physicalIndex: Int) -> Int {
        let i = physicalIndex % TabCategory.allCases.count

        if i >= 0 {
            return i
        }

        return i + TabCategory.allCases.count
    }
}

extension PagingRootViewController: PagingViewControllerInfiniteDataSource {
    func pagingViewController<T>(_ pagingViewController: PagingViewController<T>, viewControllerForPagingItem pagingItem: T) -> UIViewController {
        guard let item = pagingItem as? PagingIndexItem else {
            return UIViewController()
        }

        let i = PagingRootViewController.calcLogicalIndex(physicalIndex: item.index)
        let tc = PagingRootViewController.getCategory(index: i)

        switch tc {
        case .timeline:
            guard let isLogin = currentUser?.isTwitterLogin, isLogin else {
                let vc = LoginViewController.initFromStoryBoard()
                vc.item = item
                vc.delegate = self
                return vc
            }

            let vc = CategoryViewController.initFromStoryBoard()
            let vm = TimelineArticleListViewModel(delegate: vc, type: .timeline)
            vc.set(vm: vm)
            return vc

        case .all, .economics, .entertainment, .fun, .game, .it, .knowledge, .social, .life:
            let vc = CategoryViewController.initFromStoryBoard()
            let vm = CategoryArticleListViewModel(delegate: vc, type: .category(tc.category))
            vc.set(vm: vm)
            return vc
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
    func pagingViewController<T: PagingItem>(
        _ pagingViewController: PagingViewController<T>,
        widthForPagingItem pagingItem: T,
        isSelected: Bool
    ) -> CGFloat? where T : PagingItem, T : Comparable, T : Hashable {
        guard let currentItem = pagingItem as? PagingIndexItem else { return nil }
        let categoryIndex = PagingRootViewController.calcLogicalIndex(physicalIndex: currentItem.index)
        let category = PagingRootViewController.getCategory(index: categoryIndex)
        let l = UILabel()
        l.text = category.displayString
        l.sizeToFit()
        return l.frame.size.width + 20
    }
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
                return
            }

            self.pagingViewController.visibleItems.items.forEach { i in
                let tc = TabCategory.timeline
                let index = PagingRootViewController.getIndex(c: tc)
                guard i.index == index else { return }
                self.pagingViewController.reloadData(around: i)
                let pi = PagingIndexItem(index: index, title: tc.displayString)
                self.pagingViewController.select(pagingItem: pi)
            }
        }
    }
}
