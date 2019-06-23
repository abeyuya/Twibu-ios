//
//  CommentRepository.swift
//  Twibu
//
//  Created by abeyuya on 2019/06/21.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import FirebaseAuth
import FirebaseFirestore
import FirebaseFunctions

final class CommentRepository {
    private static let db = Firestore.firestore()
    private static let functions = Functions.functions(region: "asia-northeast1")

    static func fetchBookmarkComment(bookmarkUid: String, completion: @escaping (Result<[Comment]>) -> Void) {
        guard Auth.auth().currentUser != nil else {
            completion(.failure(.needFirebaseAuth("need firebase login")))
            return
        }

        db.collection("bookmarks")
            .document(bookmarkUid)
            .collection("comments")
            .order(by: "favorite_count", descending: true)
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

    static func execUpdateBookmarkComment(param: ExecUpdateBookmarkCommentParam, completion: @escaping (Result<HTTPSCallableResult?>) -> Void) {
        guard UserRepository.isTwitterLogin() else {
            completion(.failure(.needTwitterAuth("need twitter login")))
            return
        }

        functions.httpsCallable("execCreateOrUpdateBookmarkComment").call(param.toDict) { result, error in
            if let error = error {
                completion(.failure(.firestoreError(error.localizedDescription)))
                return
            }
            completion(.success(result))
        }
    }
}
