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

struct BookmarkDispatcher {
    static func fetchBookmark(
        category: Embedded.Category,
        uid: String,
        type: Repository.FetchType,
        completion: @escaping (Result<[Bookmark]>) -> Void
    ) {
        let lResult = Repository.Result<[Bookmark]>(item: [], lastSnapshot: nil, hasMore: false)
        let startLoadingAction = AddBookmarksAction(
            category: category,
            bookmarks: .loading(lResult)
        )
        store.mDispatch(startLoadingAction)

        let trace = Performance.startTrace(name: "fetchBookmark.\(category.rawValue).\(type.debugName)")
        BookmarkRepository.fetchBookmark(db: TwibuFirebase.shared.firestore, category: category, uid: uid, type: type) { result in
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
}
