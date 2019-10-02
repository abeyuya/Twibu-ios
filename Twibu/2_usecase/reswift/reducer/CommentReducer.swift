//
//  CommentReducer.swift
//  Twibu
//
//  Created by abeyuya on 2019/10/02.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import ReSwift
import Embedded

enum CommentReducer {
    struct Info {
        var result: Repository.Result<[Comment]>
        var state: Repository.ResponseState
    }

    typealias State = [String: Info]

    enum Actions {
        struct UpdateState: Action {
            let bookmarkUid: String
            let state: Repository.ResponseState
        }
        struct Add: Action {
            let bookmarkUid: String
            let comments: Repository.Result<[Comment]>
        }
    }

    static func reducer(action: Action, state: State?) -> State {
        var state = state ?? State()

        switch action {
        case let a as Actions.Add:
            let old = state[a.bookmarkUid]?.result.item ?? []
            let add = a.comments.item
            let newComments = Comment
                .merge(base: old, add: add)
                .sorted { $0.favorite_count > $1.favorite_count }

            state[a.bookmarkUid] = {
                if let i = state[a.bookmarkUid] {
                    return Info(
                        result: Repository.Result<[Comment]>(
                            item: newComments,
                            pagingInfo: a.comments.pagingInfo,
                            hasMore: a.comments.hasMore
                        ),
                        state: i.state
                    )
                }
                return Info(
                    result: Repository.Result<[Comment]>(item: [], pagingInfo: nil, hasMore: false),
                    state: .notYetLoading
                )
            }()


        case let a as Actions.UpdateState:
            state[a.bookmarkUid] = {
                if let i = state[a.bookmarkUid] {
                    return Info(result: i.result, state: a.state)
                }
                return Info(
                    result: Repository.Result<[Comment]>(
                        item: [],
                        pagingInfo: nil,
                        hasMore: true
                    ),
                    state: a.state
                )
            }()

        default:
            break
        }

        return state
    }
}
