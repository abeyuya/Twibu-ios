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

    private var lastSpanshot: [String: DocumentSnapshot] = [:]

    static func fetchBookmarkComment(
        bookmarkUid: String,
        type: Repository.FetchType,
        completion: @escaping (Result<([Comment], Bool)>
    ) -> Void) {
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

                if let last = snapshot.documents.last {
                    shared.lastSpanshot[bookmarkUid] = last
                }

                let hasMore = !snapshot.documents.isEmpty

                let comments = snapshot.documents.compactMap { Comment(dictionary: $0.data()) }
                completion(.success((comments, hasMore)))
        }
    }

    private static func buildQuery(bookmarkUid: String, type: Repository.FetchType) -> Query {
        let q = db.collection("bookmarks")
            .document(bookmarkUid)
            .collection("comments")
            .order(by: "favorite_count", descending: true)
            .limit(to: 100)

        if type == .new {
            return q
        }

        guard let last = shared.lastSpanshot[bookmarkUid] else {
            return q
        }

        return q.start(afterDocument: last)
    }

    struct ExecUpdateBookmarkCommentParam {
        let bookmarkUid: String
        let url: String

        var toDict: [String: String] {
            return [
                "bookmark_uid": bookmarkUid,
                "url": url
            ]
        }
    }

    //
    // NOTE: 検索で引っかかった分だけしか返さないので注意
    //
    static func execUpdateBookmarkComment(param: ExecUpdateBookmarkCommentParam, completion: @escaping (Result<[Comment]?>) -> Void) {
        guard UserRepository.isTwitterLogin() else {
            completion(.failure(.needTwitterAuth("need twitter login")))
            return
        }

        TwibuFirebase.functions.httpsCallable("execCreateOrUpdateBookmarkComment").call(param.toDict) { result, error in
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
