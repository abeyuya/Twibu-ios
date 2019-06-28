//
//  ReSwiftImpl.swift
//  Twibu
//
//  Created by abeyuya on 2019/06/23.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import Foundation
import ReSwift

struct AppState: StateType {
    struct Response {
        var bookmarks: [Category: Repository.Response<[Bookmark]>] = [:]
        var comments: [String: Repository.Response<[Comment]>] = [:]
    }

    var response: Response = Response()
}

extension AppState {
    static func toFlat(bookmarks: [Category: Repository.Response<[Bookmark]>]) -> [Bookmark] {
        let resArr = bookmarks.values.compactMap { $0 }
        let bmNestArr: [[Bookmark]] = resArr.compactMap { (res: Repository.Response<[Bookmark]>) in
            switch res {
            case .success(let result): return result.item
            case .loading(let result): return result.item
            case .failure: return nil
            case .notYetLoading: return nil
            }
        }
        let bmArr: [Bookmark] = bmNestArr.reduce([], +)
        return bmArr
    }
}

struct AddBookmarksAction: Action {
    let category: Category
    let bookmarks: Repository.Response<[Bookmark]>
}
struct AddCommentsAction: Action {
    let bookmarkUid: String
    let comments: Repository.Response<[Comment]>
}
struct UpdateBookmarkCommentCountAction: Action {
    let bookmarkUid: String
    let commentCount: Int
}

func appReducer(action: Action, state: AppState?) -> AppState {
    var state = state ?? AppState()

    switch action {
    case let a as AddBookmarksAction:
        let old: [Bookmark] = {
            let s = state.response.bookmarks[a.category] ?? .notYetLoading
            switch s {
            case .success(let res):
                return res.item
            case .loading(let res):
                return res.item
            default:
                return []
            }
        }()

        let add: [Bookmark] = {
            switch a.bookmarks {
            case .success(let res):
                return res.item
            case .loading(let res):
                return res.item
            default:
                return []
            }
        }()

        let new = Bookmark
            .merge(base: old, add: add)
            .sorted { $0.created_at ?? 0 > $1.created_at ?? 0 }

        state.response.bookmarks[a.category] = {
            switch a.bookmarks {
            case .success(let old):
                let result = Repository.Result(
                    item: new,
                    lastSnapshot: old.lastSnapshot,
                    hasMore: old.hasMore
                )
                return .success(result)
            case .loading(let old):
                let result = Repository.Result(
                    item: new,
                    lastSnapshot: old.lastSnapshot,
                    hasMore: old.hasMore
                )
                return .loading(result)
            case .failure: return a.bookmarks
            case .notYetLoading: return .notYetLoading
            }
        }()

    case let a as AddCommentsAction:
        let old: [Comment] = {
            let s = state.response.comments[a.bookmarkUid] ?? .notYetLoading
            switch s {
            case .success(let res):
                return res.item
            case .loading(let res):
                return res.item
            default:
                return []
            }
        }()

        let add: [Comment] = {
            switch a.comments {
            case .success(let res):
                return res.item
            case .loading(let res):
                return res.item
            default:
                return []
            }
        }()

        let new = Comment
            .merge(base: old, add: add)
            .sorted { $0.favorite_count > $1.favorite_count }

        state.response.comments[a.bookmarkUid] = {
            switch a.comments {
            case .success(let old):
                let result = Repository.Result<[Comment]>(
                    item: new,
                    lastSnapshot: old.lastSnapshot,
                    hasMore: old.hasMore
                )
                return .success(result)
            case .loading(let old):
                let result = Repository.Result<[Comment]>(
                    item: new,
                    lastSnapshot: old.lastSnapshot,
                    hasMore: old.hasMore
                )
                return .loading(result)
            case .failure(_): return a.comments
            case .notYetLoading: return .notYetLoading
            }
        }()

    case let a as UpdateBookmarkCommentCountAction:
//        guard let b = pickupBookmarkFromStore(
//            bookmarkUid: a.bookmarkUid,
//            bookmarks: state.response.bookmarks
//            ) else { break }
//
//        if b.comment_count ?? 0 < a.commentCount {
//            let new = Bookmark(b, commentCount: a.commentCount)
//        }
        break

    default:
        break
    }

    return state
}

//private func pickupBookmarkFromStore(
//    bookmarkUid: String,
//    bookmarks: [Category: ResponseState<[Bookmark]>]
//) -> Bookmark? {
//    let bmArr = AppState.toFlat(bookmarks: bookmarks)
//    return bmArr.first { $0.uid == bookmarkUid }
//}

//private func getReplaceInfo(b: Bookmark, bookmarks: [Category: ResponseState<[Bookmark]>]) -> (Category?, Int?) {
//    var category: Category? = nil
//    var index: Int? = nil
//
//    bookmarks.forEach { c, res in
//        let resArr: [ResponseState<[Bookmark]>] = res.compactMap { $0 }
//    }
//
//    return (category, index)
//}
//
//private func buildReplaced(bookmarkUid: String, res: ResponseState<[Bookmark]>) {
//
//}

let store = Store(
    reducer: appReducer,
    state: AppState(),
    middleware: []
)

extension Store {
    func mDispatch(_ action: Action) {
        DispatchQueue.main.async {
            self.dispatch(action)
        }
    }
}
