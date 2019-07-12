//
//  BookmarkDispatcher.swift
//  Twibu
//
//  Created by abeyuya on 2019/06/23.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import Foundation
import FirebasePerformance

struct BookmarkDispatcher {
    static func fetchBookmark(category: Category, uid: String, type: Repository.FetchType) {
        let result = Repository.Result<[Bookmark]>(item: [], lastSnapshot: nil, hasMore: false)
        let startLoadingAction = AddBookmarksAction(
            category: category,
            bookmarks: .loading(result)
        )
        store.mDispatch(startLoadingAction)

        let trace = Performance.startTrace(name: "fetchBookmark.\(category.rawValue).\(type.debugName)")
        BookmarkRepository.fetchBookmark(category: category, uid: uid, type: type) { result in
            trace?.stop()
            let a = AddBookmarksAction(
                category: category,
                bookmarks: result
            )
            store.mDispatch(a)
        }
    }
}
