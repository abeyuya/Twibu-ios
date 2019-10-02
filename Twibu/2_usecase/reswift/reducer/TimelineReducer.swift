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
        var twitterTimelineMaxId: String?
    }

    enum Actions {
        struct SetTweetMaxId: Action {
            let tweetMaxId: String
        }
    }

    static func reducer(action: Action, state: State?) -> State {
        var state = state ?? State()

        switch action {
        case let a as Actions.SetTweetMaxId:
            state.twitterTimelineMaxId = a.tweetMaxId
        default:
            break
        }

        return state
    }
}
