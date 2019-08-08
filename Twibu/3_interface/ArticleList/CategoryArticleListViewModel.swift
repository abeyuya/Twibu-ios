//
//  ArticleListViewModel.swift
//  Twibu
//
//  Created by abeyuya on 2019/08/08.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import Embedded
import ReSwift

final class CategoryArticleListViewModel: ArticleList {
    internal weak var delegate: ArticleListDelegate?
    private var response: Repository.Response<[Bookmark]> = .notYetLoading
    private var category: Embedded.Category {
        switch type {
        case .category(let c):
            return c
        }
    }

    var type: ArticleListType = .category(.all)
    var currentUser: TwibuUser?
    var bookmarks: [Bookmark] {
        return response.item ?? []
    }
}

// input
extension CategoryArticleListViewModel {
    func set(delegate: ArticleListDelegate, type: ArticleListType) {
        self.delegate = delegate
        self.type = type
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
        guard let uid = currentUser?.firebaseAuthUser?.uid else { return }

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
            guard let uid = currentUser?.firebaseAuthUser?.uid, result.hasMore else { return }

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
            delegate?.render(state: .notYetLoading)
            fetchBookmark()
            return
        }

        response = res
        delegate?.render(state: convert(res))
    }

    private func convert(_ res: Repository.Response<[Bookmark]>) -> RenderState {
        switch res {
        case .success(let result):
            return .success(hasMore: result.hasMore)
        case .loading(_):
            return .loading
        case .failure(let error):
            return .failure(error: error)
        case .notYetLoading:
            return .notYetLoading
        }
    }
}
