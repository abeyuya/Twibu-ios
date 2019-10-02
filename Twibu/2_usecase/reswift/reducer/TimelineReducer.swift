//
//  TimelineReducer.swift
//  Twibu
//
//  Created by abeyuya on 2019/10/02.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import ReSwift
import Embedded

enum TimelineReducer {
    struct State {
        var result: Repository.Result<[(Timeline, Bookmark)]>?
        var state: Repository.ResponseState = .notYetLoading
        var twitterTimelineMaxId: String?
        var lastRefreshAt: Date?
    }

    enum Actions {
        struct UpdateState: Action {
            let state: Repository.ResponseState
        }
        struct AddTimelines: Action {
            let result: Repository.Result<[(Timeline, Bookmark)]>
        }
        struct Clear: Action {}
        struct SetTweetMaxId: Action {
            let tweetMaxId: String
        }
        struct SetLastRefreshAt: Action {
            let refreshAt: Date
        }
    }

    static func reducer(action: Action, state: State?) -> State {
        var state = state ?? State()

        switch action {
        case let a as Actions.UpdateState:
            state.state = a.state

        case let a as Actions.AddTimelines:
            let old = state.result?.item ?? []
            let add = a.result.item
            let all = old + add
            let uniqued: [(Timeline, Bookmark)] = all.reduce([]) { prev, next in
                let buids = prev.compactMap { $0.1.uid }
                return buids.contains(next.1.uid) ? prev : prev + [next]
            }
            let sorted = uniqued.sorted { a, b in
                return a.0.post_at > b.0.post_at
            }
            state.result = .init(
                item: sorted,
                pagingInfo: a.result.pagingInfo,
                hasMore: a.result.hasMore
            )

        case _ as Actions.Clear:
            state.result = .init(
                item: [],
                pagingInfo: nil,
                hasMore: true
            )

        case let a as Actions.SetTweetMaxId:
            state.twitterTimelineMaxId = a.tweetMaxId

        case let a as Actions.SetLastRefreshAt:
            state.lastRefreshAt = a.refreshAt

        default:
            break
        }

        return state
    }
}
