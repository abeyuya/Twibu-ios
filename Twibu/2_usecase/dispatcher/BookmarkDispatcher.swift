//
//  BookmarkDispatcher.swift
//  Twibu
//
//  Created by abeyuya on 2019/06/23.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import Foundation

struct BookmarkDispatcher {
    static func fetchBookmark(category: Category) {
        let startLoadingAction = AddBookmarksAction(
            category: category,
            bookmarks: .loading([])
        )
        store.mDispatch(startLoadingAction)

        BookmarkRepository.fetchBookmark(category: category) { result in
            switch result {
            case .success(let res):
                let a = AddBookmarksAction(
                    category: category,
                    bookmarks: .success(res)
                )
                store.mDispatch(a)
            case .failure(let error):
                let a = AddBookmarksAction(
                    category: category,
                    bookmarks: .faillure(error)
                )
                store.mDispatch(a)
            }
        }
    }
}
