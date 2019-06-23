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

struct AddBookmarksAction: Action {
    let category: Category
    let bookmarks: ResponseState<[Bookmark]>
}
struct AddCommentsAction: Action {
    let bookmarkUid: String
    let comments: ResponseState<[Comment]>
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

        let new = Bookmark.merge(base: old, add: add)

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

        let new = Comment.merge(base: old, add: add)

        state.response.comments[a.bookmarkUid] = {
            switch a.comments {
            case .loading: return .loading(new)
            case .faillure(_): return a.comments
            case .notYetLoading: return .notYetLoading
            case .success(_): return .success(new)
            }
        }()

    default:
        break
    }

    return state
}

let store = Store(
    reducer: appReducer,
    state: AppState(),
    middleware: []
)
