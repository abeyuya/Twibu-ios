//
//  BookmarkDispatcher.swift
//  Twibu
//
//  Created by abeyuya on 2019/06/23.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import Foundation

struct BookmarkDispatcher {
    static func fetchBookmark(category: Category, uid: String, type: Repository.FetchType) {
        let result = Repository.Result<[Bookmark]>(item: [], lastSnapshot: nil, hasMore: false)
        let startLoadingAction = AddBookmarksAction(
            category: category,
            bookmarks: .loading(result)
        )
        store.mDispatch(startLoadingAction)

        BookmarkRepository.fetchBookmark(category: category, uid: uid, type: type) { result in
            let a = AddBookmarksAction(
                category: category,
                bookmarks: result
            )
            store.mDispatch(a)
        }
    }
}
