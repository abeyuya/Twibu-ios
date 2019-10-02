//
//  TimelineDispatcher.swift
//  Twibu
//
//  Created by abeyuya on 2019/10/03.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import Embedded

enum TimelineDispatcher {
    static func fetchTimeline(
        userUid: String,
        type: Repository.FetchType,
        completion: @escaping (Result<[Bookmark]>) -> Void
    ) {
        switch type {
        case .add:
            updateState(s: .additionalLoading)
        case .new:
            updateState(s: .loading)
            let a = TimelineReducer.Actions.SetLastRefreshAt(refreshAt: Date())
            store.mDispatch(a)
        }

        TimelineRepository.fetchTimeline(userUid: userUid, type: type) { result in
            switch result {
            case .failure(let e):
                updateState(s: .failure(e))
            case .success(let res):
                let a = TimelineReducer.Actions.AddTimelines(result: res)
                store.mDispatch(a)
                updateState(s: .success)
            }
        }
    }

    static func clear() {
        let a = TimelineReducer.Actions.Clear()
        store.mDispatch(a)
    }

    static func updateState(s: Repository.ResponseState) {
        let a = TimelineReducer.Actions.UpdateState(state: s)
        store.mDispatch(a)
    }
}
