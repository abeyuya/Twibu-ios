//
//  BookmarkRepository.swift
//  Twibu
//
//  Created by abeyuya on 2019/06/21.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import FirebaseAuth
import FirebaseFirestore

final class BookmarkRepository {
    private static let db = TwibuFirebase.firestore

    static func fetchBookmark(category: Category, completion: @escaping (Result<[Bookmark]>) -> Void) {
        guard Auth.auth().currentUser != nil else {
            completion(.failure(.needFirebaseAuth("need firebase login")))
            return
        }

        buildQuery(category: category).getDocuments() { snapshot, error in
            if let error = error {
                completion(.failure(.firestoreError(error.localizedDescription)))
                return
            }

            guard let snapshot = snapshot else {
                completion(.failure(.firestoreError("no result")))
                return
            }

            let bookmarks = snapshot.documents.compactMap { Bookmark(dictionary: $0.data()) }
            completion(.success(bookmarks))
        }
    }

    static private func buildQuery(category: Category) -> Query {
        switch category {
        case .all:
            return db.collection("bookmarks")
                .order(by: "created_at", descending: true)
                .order(by: "comment_count", descending: true)
                .limit(to: 30)
        case .timeline:
            return db.collection("bookmarks")
                .order(by: "created_at", descending: true)
                .limit(to: 30)
        default:
            return db.collection("bookmarks")
                .whereField("category", isEqualTo: category.rawValue)
                .order(by: "created_at", descending: true)
                .limit(to: 30)
        }
    }

    static func createOrUpdateBookmark(url: String) {
    }
}
