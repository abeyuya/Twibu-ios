//
//  ReSwiftImpl.swift
//  Twibu
//
//  Created by abeyuya on 2019/06/23.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import Foundation
import ReSwift
import Embedded

struct AppState: StateType {
    var history = HistoryReducer.State()
    var category = CategoryReducer.State()
    var comment = CommentReducer.State()
    var webArchive = WebArchiveReducer.State()
    var currentUser = CurrentUserReducer.State(firebaseAuthUser: nil)

    var twitterTimelineMaxId: String?
}

struct SetMaxIdAction: Action {
    let maxId: String
}
func appReducer(action: Action, state: AppState?) -> AppState {
    var s = dummyReducer(action: action, state: state)
    s.history = HistoryReducer.reducer(action: action, state: state?.history)
    s.category = CategoryReducer.reducer(action: action, state: state?.category)
    s.comment = CommentReducer.reducer(action: action, state: state?.comment)
    s.webArchive = WebArchiveReducer.reducer(action: action, state: state?.webArchive)
    s.currentUser = CurrentUserReducer.reducer(action: action, state: state?.currentUser)
    return s
}

private func dummyReducer(action: Action, state: AppState?) -> AppState {
    var state = state ?? AppState()

    switch action {
    case let a as SetMaxIdAction:
        state.twitterTimelineMaxId = a.maxId


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
