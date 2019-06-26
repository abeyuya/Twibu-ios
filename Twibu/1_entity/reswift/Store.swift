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
        var bookmarks: [Category: ResponseState<[Bookmark]>] = [:]
        var comments: [String: ResponseState<[Comment]>] = [:]
    }

    var response: Response = Response()
}

extension AppState {
    static func toFlat(bookmarks: [Category: ResponseState<[Bookmark]>]) -> [Bookmark] {
        let resArr: [ResponseState<[Bookmark]>] = bookmarks.values.compactMap { $0 }
        let bmNestArr: [[Bookmark]] = resArr.compactMap { (res: ResponseState<[Bookmark]>) in
            switch res {
            case .loading(let bms): return bms;
            case .faillure(_): return nil
            case .notYetLoading: return nil
            case .success(let bms): return bms
            }
        }
        let bmArr: [Bookmark] = bmNestArr.reduce([], +)
        return bmArr
    }
}

struct AddBookmarksAction: Action {
    let category: Category
    let bookmarks: ResponseState<[Bookmark]>
}
struct AddCommentsAction: Action {
    let bookmarkUid: String
    let comments: ResponseState<[Comment]>
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
            case .success(let before):
                return before
            case .loading(let before):
                return before
            default:
                return []
            }
        }()

        let add: [Bookmark] = {
            switch a.bookmarks {
            case .success(let add):
                return add
            case .loading(let add):
                return add
            default:
                return []
            }
        }()

        let new = Bookmark
            .merge(base: old, add: add)
            .sorted { $0.created_at ?? 0 > $1.created_at ?? 0 }

        state.response.bookmarks[a.category] = {
            switch a.bookmarks {
            case .loading: return .loading(new)
            case .faillure(_): return a.bookmarks
            case .notYetLoading: return .notYetLoading
            case .success(_): return .success(new)
            }
        }()

    case let a as AddCommentsAction:
        let old: [Comment] = {
            let s = state.response.comments[a.bookmarkUid] ?? .notYetLoading
            switch s {
            case .success(let before):
                return before
            case .loading(let before):
                return before
            default:
                return []
            }
        }()

        let add: [Comment] = {
            switch a.comments {
            case .success(let add):
                return add
            case .loading(let add):
                return add
            default:
                return []
            }
        }()

        let new = Comment
            .merge(base: old, add: add)
            .sorted { $0.favorite_count > $1.favorite_count }

        state.response.comments[a.bookmarkUid] = {
            switch a.comments {
            case .loading: return .loading(new)
            case .faillure(_): return a.comments
            case .notYetLoading: return .notYetLoading
            case .success(_): return .success(new)
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

private func pickupBookmarkFromStore(
    bookmarkUid: String,
    bookmarks: [Category: ResponseState<[Bookmark]>]
) -> Bookmark? {
    let bmArr = AppState.toFlat(bookmarks: bookmarks)
    return bmArr.first { $0.uid == bookmarkUid }
}

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
