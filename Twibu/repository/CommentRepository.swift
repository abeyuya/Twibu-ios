//
//  CommentRepository.swift
//  Twibu
//
//  Created by abeyuya on 2019/06/21.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import FirebaseAuth
import FirebaseFirestore

final class CommentRepository {
    private static let db = Firestore.firestore()

    static func fetchBookmarkComment(bookmarkUid: String, completion: @escaping (Result<[Comment], Error>) -> Void) {
        guard Auth.auth().currentUser != nil else {
            completion(.failure(NSError.init(domain: "", code: 500, userInfo: ["message": "need login"])))
            return
        }

        db.collection("bookmarks")
            .document(bookmarkUid)
            .collection("comments")
            .order(by: "favorite_count", descending: true)
            .getDocuments() { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                guard let snapshot = snapshot else {
                    completion(.failure(NSError.init(domain: "", code: 500, userInfo: ["message": "no result"])))
                    return
                }

                let comments = snapshot.documents.compactMap { Comment(dictionary: $0.data()) }
                completion(.success(comments))
        }
    }
}
