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
    var history = HistoryReducer.State()
    var category = CategoryReducer.State()
    var comment = CommentReducer.State()
    var webArchive = WebArchiveReducer.State()

    var currentUser = TwibuUser(firebaseAuthUser: nil)
    var twitterTimelineMaxId: String?
    var lastRefreshAt: [Embedded.Category: Date] = [:]
}

struct UpdateFirebaseUserAction: Action {
    let newUser: User
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
    s.comment = CommentReducer.reducer(action: action, state: state?.comment)
    s.webArchive = WebArchiveReducer.reducer(action: action, state: state?.webArchive)
    return s
}

private func dummyReducer(action: Action, state: AppState?) -> AppState {
    var state = state ?? AppState()

    switch action {
    case let a as UpdateFirebaseUserAction:
        let newUser = TwibuUser(firebaseAuthUser: a.newUser)
        state.currentUser = newUser

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
