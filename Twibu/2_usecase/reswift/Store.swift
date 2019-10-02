//
//  ReSwiftImpl.swift
//  Twibu
//
//  Created by abeyuya on 2019/06/23.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import ReSwift
import Embedded

struct AppState: StateType {
    var history = HistoryReducer.State()
    var category = CategoryReducer.State()
    var comment = CommentReducer.State()
    var webArchive = WebArchiveReducer.State()
    var currentUser = CurrentUserReducer.State(firebaseAuthUser: nil)
    var timeline = TimelineReducer.State()
    var memo = MemoReducer.State()
}

private func appReducer(action: Action, state: AppState?) -> AppState {
    return AppState(
        history: HistoryReducer.reducer(action: action, state: state?.history),
        category: CategoryReducer.reducer(action: action, state: state?.category),
        comment: CommentReducer.reducer(action: action, state: state?.comment),
        webArchive: WebArchiveReducer.reducer(action: action, state: state?.webArchive),
        currentUser: CurrentUserReducer.reducer(action: action, state: state?.currentUser),
        timeline: TimelineReducer.reducer(action: action, state: state?.timeline),
        memo: MemoReducer.reducer(action: action, state: state?.memo)
    )
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
