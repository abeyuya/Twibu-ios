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
        commentCountOffset: Int,
        completion: @escaping (Result<[Bookmark]>) -> Void
    ) {
        updateState(c: category, s: .loading)

        switch type {
        case .add:
            break
        case .new:
            let a = SetLastRefreshAtAction(category: category, refreshAt: Date())
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
                let a = AddBookmarksAction(
                    category: category,
                    bookmarks: res
                )
                store.mDispatch(a)
                updateState(c: category, s: .success)
            }
        }
    }

    static func clearCategory(c: Embedded.Category) {
        let a = ClearBookmarkAction(category: c)
        store.mDispatch(a)
    }

    static func updateState(c: Embedded.Category, s: Repository.ResponseState) {
        let a = UpdateBookmarkStateAction(category: c, state: s)
        store.mDispatch(a)
    }
}
