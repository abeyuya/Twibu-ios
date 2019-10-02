//
//  BookmarkDispatcher.swift
//  Twibu
//
//  Created by abeyuya on 2019/06/23.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import Foundation
import FirebasePerformance
import Embedded

enum BookmarkDispatcher {
    static func fetchBookmark(
        category: Embedded.Category,
        uid: String,
        type: Repository.FetchType,
        commentCountOffset: Int
    ) {
        switch type {
        case .add:
            updateState(c: category, s: .additionalLoading)
        case .new:
            updateState(c: category, s: .loading)
            let a = CategoryReducer.Actions.SetLastRefreshAt(category: category, refreshAt: Date())
            store.mDispatch(a)
        }

        let trace = Performance.startTrace(name: "fetchBookmark.\(category.rawValue).\(type.debugName)")
        BookmarkRepository.fetchBookmark(
            category: category,
            uid: uid,
            type: type,
            commentCountOffset: commentCountOffset
        ) { result in
            trace?.stop()

            switch result {
            case .failure(let e):
                updateState(c: category, s: .failure(e))
            case .success(let res):
                let a = CategoryReducer.Actions.AddBookmarks(
                    category: category,
                    result: res
                )
                store.mDispatch(a)
                updateState(c: category, s: .success)
            }
        }
    }

    static func clearCategory(c: Embedded.Category) {
        let a = CategoryReducer.Actions.ClearCategory(category: c)
        store.mDispatch(a)
    }

    static func updateState(c: Embedded.Category, s: Repository.ResponseState) {
        let a = CategoryReducer.Actions.UpdateState(category: c, state: s)
        store.mDispatch(a)
    }
}
