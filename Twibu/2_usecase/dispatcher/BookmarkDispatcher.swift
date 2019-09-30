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
        setLoading(c: category)

        switch type {
        case .add(_, _):
            break
        case .new(_):
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
                let r = Repository.Result<[Bookmark]>(
                    item: [],
                    pagingInfo: nil,
                    hasMore: false
                )
                let a = AddBookmarksAction(
                    category: category,
                    bookmarks: .failure(r, e)
                )
                store.mDispatch(a)
            case .success(let res):
                let a = AddBookmarksAction(
                    category: category,
                    bookmarks: res
                )
                store.mDispatch(a)

                switch res {
                case .failure(_, let e):
                    completion(.failure(e))
                case .loading(_), .notYetLoading:
                    completion(.failure(.firestoreError(nil)))
                case .success(let r):
                    completion(.success(r.item))
                }
            }
        }
    }

    static func clearCategory(c: Embedded.Category) {
        let a = ClearCategoryAction(category: c)
        store.mDispatch(a)
    }

    static func setLoading(c: Embedded.Category) {
        let r = Repository.Result<[Bookmark]>(item: [], pagingInfo: nil, hasMore: false)
        let a = AddBookmarksAction(
            category: c,
            bookmarks: .loading(r)
        )
        store.mDispatch(a)
    }

    static func setError(c: Embedded.Category, e: TwibuError) {
        let r = Repository.Result<[Bookmark]>(item: [], pagingInfo: nil, hasMore: false)
        let a = AddBookmarksAction(
            category: c,
            bookmarks: .failure(r, e)
        )
        store.mDispatch(a)
    }
}
