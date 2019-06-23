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
        store.dispatch(startLoadingAction)

        BookmarkRepository.fetchBookmark(category: category) { result in
            switch result {
            case .success(let bookmarks):
                let a = AddBookmarksAction(
                    category: category,
                    bookmarks: .success(bookmarks)
                )
                store.dispatch(a)
            case .failure(let error):
                let a = AddBookmarksAction(
                    category: category,
                    bookmarks: .faillure(error)
                )
                store.dispatch(a)
            }
        }
    }
}
