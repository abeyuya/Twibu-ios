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
    private static let shared = CommentRepository()
    private init() {}
    private static let db = TwibuFirebase.firestore

    static func fetchBookmarkComment(
        bookmarkUid: String,
        type: Repository.FetchType,
        completion: @escaping ((Result<[Comment]>) -> Void)
    ) {
        guard Auth.auth().currentUser != nil else {
            completion(.failure(.needFirebaseAuth("need firebase login")))
            return
        }

        buildQuery(bookmarkUid: bookmarkUid, type: type)
            .getDocuments() { snapshot, error in
                if let error = error {
                    completion(.failure(.firestoreError(error.localizedDescription)))
                    return
                }

                guard let snapshot = snapshot else {
                    completion(.failure(.firestoreError("no result")))
                    return
                }

                let comments = snapshot.documents.compactMap { Comment(dictionary: $0.data()) }
                completion(.success(comments))
        }
    }

    private static func buildQuery(bookmarkUid: String, type: Repository.FetchType) -> Query {
        let q = db.collection("bookmarks")
            .document(bookmarkUid)
            .collection("comments")
            .order(by: "favorite_count", descending: true)

        if type == .new {
            return q.limit(to: 100)
        }

//        return q.start(afterDocument: last).limit(to: 100)
        return q.limit(to: 100)
    }

    //
    // NOTE: 検索で引っかかった分だけしか返さないので注意
    //
    static func execUpdateBookmarkComment(
        bookmarkUid: String,
        url: String,
        completion: @escaping (Result<[Comment]?>
    ) -> Void) {
        guard UserRepository.isTwitterLogin() else {
            completion(.failure(.needTwitterAuth("need twitter login")))
            return
        }

        let param = [
            "bookmark_uid": bookmarkUid,
            "url": url
        ]

        TwibuFirebase.functions.httpsCallable("execCreateOrUpdateBookmarkComment").call(param) { result, error in
            if let error = error {
                completion(.failure(.firestoreError(error.localizedDescription)))
                return
            }

            guard let res = result?.data as? [String: Any] else {
                completion(.success(nil))
                return
            }

            guard let rawComments = res["comments"] as? [[String: Any]] else {
                completion(.success(nil))
                return
            }

            let comments = rawComments.compactMap { Comment(dictionary: $0) }
            completion(.success(comments))
        }
    }
}
