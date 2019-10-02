//
//  ReSwiftImpl.swift
//  Twibu
//
//  Created by abeyuya on 2019/06/23.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import Foundation
import ReSwift
import FirebaseAuth
import Embedded

struct AppState: StateType {
    struct ResponseData {
        var comments: [String: Repository.Result<[Comment]>] = [:]
    }

    struct ResponseState {
        var comments: [String: Repository.ResponseState] = [:]
    }

    struct WebArchiveInfo {
        var tasks: [WebArchiver] = []
        var results: [(bookmarkUid: String, result: WebArchiver.SaveResult)] = []
    }

    var responseData = ResponseData()
    var responseState = ResponseState()
    var currentUser = TwibuUser(firebaseAuthUser: nil)
    var history = HistoryReducer.State(histories: [], hasMore: true)
    var category = CategoryReducer.State()
    var webArchive = WebArchiveInfo(tasks: [], results: [])
    var twitterTimelineMaxId: String?
    var lastRefreshAt: [Embedded.Category: Date] = [:]
}

struct UpdateCommentStateAction: Action {
    let bookmarkUid: String
    let state: Repository.ResponseState
}
struct AddCommentsAction: Action {
    let bookmarkUid: String
    let comments: Repository.Result<[Comment]>
}
struct UpdateFirebaseUserAction: Action {
    let newUser: User
}
struct AddWebArchiveTask: Action {
    let webArchiver: WebArchiver
}
struct UpdateWebArchiveResult: Action {
    let bookmarkUid: String
    let result: WebArchiver.SaveResult
}
struct SetMaxIdAction: Action {
    let maxId: String
}
struct SetLastRefreshAtAction: Action {
    let category: Embedded.Category
    let refreshAt: Date
}

func appReducer(action: Action, state: AppState?) -> AppState {
    var s = dummyReducer(action: action, state: state)
    s.history = HistoryReducer.reducer(action: action, state: state?.history)
    s.category = CategoryReducer.reducer(action: action, state: state?.category)
    return s
}

private func dummyReducer(action: Action, state: AppState?) -> AppState {
    var state = state ?? AppState()

    switch action {
    case let a as AddCommentsAction:
        let old = state.responseData.comments[a.bookmarkUid]?.item ?? []
        let add = a.comments.item
        let newComments = Comment
            .merge(base: old, add: add)
            .sorted { $0.favorite_count > $1.favorite_count }
        state.responseData.comments[a.bookmarkUid] = Repository.Result<[Comment]>(
            item: newComments,
            pagingInfo: a.comments.pagingInfo,
            hasMore: a.comments.hasMore
        )

    case let a as UpdateCommentStateAction:
        state.responseState.comments[a.bookmarkUid] = a.state

    case let a as UpdateFirebaseUserAction:
        let newUser = TwibuUser(firebaseAuthUser: a.newUser)
        state.currentUser = newUser

    case let a as AddWebArchiveTask:
        state.webArchive.tasks.append(a.webArchiver)

    case let a as UpdateWebArchiveResult:
        if let i = state.webArchive.results.firstIndex(where: { $0.0 == a.bookmarkUid}) {
            state.webArchive.results[i] = (a.bookmarkUid, a.result)
        } else {
            state.webArchive.results.append((a.bookmarkUid, a.result))
        }

    case let a as SetMaxIdAction:
        state.twitterTimelineMaxId = a.maxId

    case let a as SetLastRefreshAtAction:
        state.lastRefreshAt[a.category] = a.refreshAt

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

extension Store {
    func mDispatch(_ action: Action) {
        DispatchQueue.main.async {
            self.dispatch(action)
        }
    }
}
