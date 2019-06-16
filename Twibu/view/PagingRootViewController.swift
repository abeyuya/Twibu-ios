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

final class PagingRootViewController: UIViewController {

    enum Category: String, CaseIterable {
        case sougou = "総合"
        case timeline = "タイムライン"
        case yononaka = "世の中"
        case seijiKeizai = "政治と経済"
        case kurashi = "暮らし"
        case manabi = "学び"
        case technology = "テクノロジー"
        case entame = "エンタメ"
        case animeGame = "アニメとゲーム"
        case omoshiro = "おもしろ"

        var index: Int {
            return Category.allCases.firstIndex(of: self)!
        }

        init?(index: Int) {
            self = Category.allCases[index]
        }

        static func calcLogicalIndex(physicalIndex: Int) -> Int {
            let i = physicalIndex % Category.allCases.count

            if i >= 0 {
                return i
            }

            return i + Category.allCases.count
        }
    }

    private let pagingViewController = PagingViewController<PagingIndexItem>()

    override func viewDidLoad() {
        super.viewDidLoad()

        setupPagingView()
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

        let c = Category.sougou
        pagingViewController.select(pagingItem: PagingIndexItem(index: c.index, title: c.rawValue))
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
            if let user = Auth.auth().currentUser {
                let storyboard = UIStoryboard(name: "TimelineViewController", bundle: nil)
                let vc = storyboard.instantiateInitialViewController() as! TimelineViewController
                return vc
            } else {
                let storyboard = UIStoryboard(name: "LoginViewController", bundle: nil)
                let vc = storyboard.instantiateInitialViewController() as! LoginViewController
                return vc
            }
        default:
            let storyboard = UIStoryboard(name: "CategoryViewController", bundle: nil)
            let vc = storyboard.instantiateInitialViewController() as! CategoryViewController
            vc.category = category
            return vc
        }
    }

    func pagingViewController<T>(_ pagingViewController: PagingViewController<T>, pagingItemBeforePagingItem pagingItem: T) -> T? {
        guard let currentItem = pagingItem as? PagingIndexItem else { return nil }
        let categoryIndex = Category.calcLogicalIndex(physicalIndex: currentItem.index - 1)
        guard let category = Category(index: categoryIndex) else { return nil }
        return PagingIndexItem(index: currentItem.index - 1, title: category.rawValue) as? T
    }

    func pagingViewController<T>(_ pagingViewController: PagingViewController<T>, pagingItemAfterPagingItem pagingItem: T) -> T? {
        guard let currentItem = pagingItem as? PagingIndexItem else { return nil }
        let categoryIndex = Category.calcLogicalIndex(physicalIndex: currentItem.index + 1)
        guard let category = Category(index: categoryIndex) else { return nil }
        return PagingIndexItem(index: currentItem.index + 1, title: category.rawValue) as? T
    }
}

extension PagingRootViewController: PagingViewControllerDelegate {

}
