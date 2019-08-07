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

final class BookmarkDispatcher {
    private init() {}

    static func fetchBookmark(
        category: Embedded.Category,
        uid: String,
        type: Repository.FetchType,
        commentCountOffset: Int,
        completion: @escaping (Result<[Bookmark]>) -> Void
    ) {
        guard category != .history else {
            assertionFailure("historyは使わないはず")
            return
        }

        let lResult = Repository.Result<[Bookmark]>(item: [], lastSnapshot: nil, hasMore: false)
        let startLoadingAction = AddBookmarksAction(
            category: category,
            bookmarks: .loading(lResult)
        )
        store.mDispatch(startLoadingAction)

        let trace = Performance.startTrace(name: "fetchBookmark.\(category.rawValue).\(type.debugName)")
        BookmarkRepository.fetchBookmark(
            db: TwibuFirebase.shared.firestore,
            category: category,
            uid: uid,
            type: type,
            commentCountOffset: commentCountOffset
        ) { result in
            trace?.stop()

            let a = AddBookmarksAction(
                category: category,
                bookmarks: result
            )
            store.mDispatch(a)

            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .loading(_), .notYetLoading:
                completion(.failure(TwibuError.firestoreError(nil)))
            case .success(let r):
                completion(.success(r.item))
            }
        }
    }

    static func fetchHistory(offset: Int) {
        HistoryRepository.fetchHistory(offset: offset) { histories in
            let bookmarks = histories.compactMap { $0.decodedBookmark() }
            let result = Repository.Result(
                item: bookmarks,
                lastSnapshot: nil,
                hasMore: !bookmarks.isEmpty
            )
            let res = Repository.Response.success(result)
            let a = AddBookmarksAction(
                category: .history,
                bookmarks: res
            )
            store.mDispatch(a)
        }
    }
}
