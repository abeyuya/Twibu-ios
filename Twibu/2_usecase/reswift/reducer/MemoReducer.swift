//
//  MemoReducer.swift
//  Twibu
//
//  Created by abeyuya on 2019/10/02.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import ReSwift
import Embedded

enum MemoReducer {
    struct State {
        var result: Repository.Result<[(Memo, Bookmark)]>?
        var state: Repository.ResponseState = .notYetLoading
    }

    enum Actions {
        struct UpdateState: Action {
            let state: Repository.ResponseState
        }
        struct Remove: Action {
            let bookmarkUid: String
        }
        struct AddMomos: Action {
            let result: Repository.Result<[(Memo, Bookmark)]>
        }
    }

    static func reducer(action: Action, state: State?) -> State {
        var state = state ?? State()

        switch action {
        case let a as Actions.UpdateState:
            state.state = a.state

        case let a as Actions.Remove:
            state.result = {
                guard let old = state.result else { return nil }
                let newItem = old.item.filter { $0.1.uid != a.bookmarkUid }
                return Repository.Result(
                    item: newItem,
                    pagingInfo: old.pagingInfo,
                    hasMore: old.hasMore
                )
            }()

        case let a as Actions.AddMomos:
            let old = state.result?.item ?? []
            let add = a.result.item
            let all = old + add
            let uniqued: [(Memo, Bookmark)] = all.reduce([]) { prev, next in
                let buids = prev.compactMap { $0.1.uid }
                return buids.contains(next.1.uid) ? prev : prev + [next]
            }
            let sorted = uniqued.sorted { a, b in
                return a.0.updated_at > b.0.updated_at
            }
            state.result = Repository.Result<[(Memo, Bookmark)]>(
                item: sorted,
                pagingInfo: a.result.pagingInfo,
                hasMore: a.result.hasMore
            )

        default:
            break
        }

        return state
    }
}
