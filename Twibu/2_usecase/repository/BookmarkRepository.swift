//
//  BookmarkRepository.swift
//  Twibu
//
//  Created by abeyuya on 2019/06/21.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import FirebaseAuth
import FirebaseFirestore
import FirebaseFunctions

final class BookmarkRepository {
    private static let db = Firestore.firestore()

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
        let common1 = db.collection("bookmarks")

        let common2: Query = {
            switch category {
            case .all:
                return common1
                    .order(by: "comment_count", descending: true)
                    .whereField("comment_count", isGreaterThan: 20)
            case .timeline:
                return common1
            default:
                return common1.whereField("category", isEqualTo: category.rawValue)
            }
        }()

        return common2
            .order(by: "created_at", descending: true)
            .limit(to: 30)
    }

    static func createOrUpdateBookmark(url: String) {
    }
}
