//
//  HistoryReducer.swift
//  Twibu
//
//  Created by abeyuya on 2019/10/02.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import ReSwift
import Embedded

enum HistoryReducer {
    struct State {
        var histories: [(bookmark: Bookmark, createdAt: Int)]
        var hasMore: Bool
    }

    struct AddHistoriesAction: Action {
        let histories: [(Bookmark, Int)]
    }
    struct AddNewHistoryAction: Action {
        let bookmark: Bookmark
        let createdAt: Int
    }
    struct DeleteHistoryAction: Action {
        let bookmarkUid: String
    }

    static func reducer(action: Action, state: State?) -> State {
        var state = state ?? State(histories: [], hasMore: true)

        switch action {
        case let a as AddHistoriesAction:
            state.histories = (state.histories + a.histories)
                .unique(by: { $0.0.uid })
                .sorted { $0.1 > $1.1 }
            state.hasMore = !a.histories.isEmpty

        case let a as AddNewHistoryAction:
            state.histories.insert((a.bookmark, a.createdAt), at: 0)
            state.histories = state.histories
                .unique(by: { $0.0.uid })
                .sorted { $0.1 > $1.1 }

        case let a as DeleteHistoryAction:
            if let index = state.histories.firstIndex(where: { $0.bookmark.uid == a.bookmarkUid }) {
                state.histories.remove(at: index)
            }

        default:
            break
        }

        return state
    }
}
