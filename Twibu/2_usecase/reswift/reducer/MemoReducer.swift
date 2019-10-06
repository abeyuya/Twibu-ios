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
    struct Info {
        var memo: Memo
        var bookmark: Bookmark
    }

    struct State {
        var result: Repository.Result<[Info]>?
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
            let result: Repository.Result<[Info]>
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
                let newItem = old.item.filter { $0.bookmark.uid != a.bookmarkUid }
                return .init(
                    item: newItem,
                    pagingInfo: old.pagingInfo,
                    hasMore: old.hasMore
                )
            }()

        case let a as Actions.AddMomos:
            let old = state.result?.item ?? []
            let add = a.result.item
            let all = old + add
            let uniqued: [Info] = all.reduce([]) { prev, next in
                let buids = prev.compactMap { $0.bookmark.uid }
                return buids.contains(next.bookmark.uid) ? prev : prev + [next]
            }
            let sorted = uniqued.sorted { a, b in
                return a.memo.updated_at > b.memo.updated_at
            }
            state.result = .init(
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
