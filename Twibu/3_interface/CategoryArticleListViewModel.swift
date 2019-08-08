//
//  ArticleListViewModel.swift
//  Twibu
//
//  Created by abeyuya on 2019/08/08.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import Embedded
import ReSwift

protocol CategoryArticleListViewModelDelegate: class {
    func render()
}

final class CategoryArticleListViewModel {
    private weak var delegate: CategoryArticleListViewModelDelegate?
    private var category: Embedded.Category!

    var currentUser: TwibuUser?
    var response: Repository.Response<[Bookmark]> = .notYetLoading
    var bookmarks: [Bookmark] {
        return response.item ?? []
    }
}

// input
extension CategoryArticleListViewModel {
    func setup(delegate: CategoryArticleListViewModelDelegate, category: Embedded.Category) {
        self.delegate = delegate
        self.category = category
    }

    func startSubscribe() {
        store.subscribe(self) { [weak self] subcription in
            subcription.select { state in
                let res: Repository.Response<[Bookmark]>? = {
                    guard let c = self?.category else { return nil }
                    return state.response.bookmarks[c]
                }()

                return Props(res: res, currentUser: state.currentUser)
            }
        }
    }

    func stopSubscribe() {
        store.unsubscribe(self)
    }

    func fetchBookmark() {
        guard let category = category, let uid = currentUser?.firebaseAuthUser?.uid else { return }

        let limit: Int = {
            switch category {
            case .all: return 100
            default: return 30
            }
        }()

        switch category {
        case .history:
            BookmarkDispatcher.fetchHistory(offset: 0)
        default:
            BookmarkDispatcher.fetchBookmark(
                category: category,
                uid: uid,
                type: .new(limit: limit),
                commentCountOffset: category == .all ? 20 : 0
            ) { _ in }
        }
    }

    func fetchAdditionalBookmarks() {
        switch response {
        case .loading(_):
            return
        case .notYetLoading:
            // view読み込み時だけ通る
            return
        case .failure(_):
            return
        case .success(let result):
            guard let category = category,
                let uid = currentUser?.firebaseAuthUser?.uid,
                result.hasMore else { return }

            switch category {
            case .history:
                BookmarkDispatcher.fetchHistory(offset: bookmarks.count)
            default:
                BookmarkDispatcher.fetchBookmark(
                    category: category,
                    uid: uid,
                    type: .add(limit: 30, last: result.lastSnapshot),
                    commentCountOffset: category == .all ? 20 : 0
                ) { _ in }
            }
        }
    }
}

extension CategoryArticleListViewModel: StoreSubscriber {
    struct Props {
        var res: Repository.Response<[Bookmark]>?
        var currentUser: TwibuUser
    }

    typealias StoreSubscriberStateType = Props

    func newState(state: Props) {
        currentUser = state.currentUser

        guard let res = state.res else {
            // 初回取得前はここを通る
            response = .notYetLoading
            delegate?.render()
            fetchBookmark()
            return
        }

        response = res
        delegate?.render()
    }
}
