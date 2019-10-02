//
//  WebArchiveReducer.swift
//  Twibu
//
//  Created by abeyuya on 2019/10/02.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import ReSwift
import Embedded

enum WebArchiveReducer {
    struct State {
        var tasks: [WebArchiver] = []
        var results: [(bookmarkUid: String, result: WebArchiver.SaveResult)] = []
    }

    enum Actions {
        struct Add: Action {
            let webArchiver: WebArchiver
        }
        struct Update: Action {
            let bookmarkUid: String
            let result: WebArchiver.SaveResult
        }
    }

    static func reducer(action: Action, state: State?) -> State {
        var state = state ?? State()

        switch action {
        case let a as Actions.Add:
            state.tasks.append(a.webArchiver)

        case let a as Actions.Update:
            if let i = state.results.firstIndex(where: { $0.0 == a.bookmarkUid}) {
                state.results[i] = (a.bookmarkUid, a.result)
            } else {
                state.results.append((a.bookmarkUid, a.result))
            }

        default:
            break
        }

        return state
    }
}
