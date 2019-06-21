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
    private static let functions = Functions.functions(region: "asia-northeast1")

    static func fetchBookmark(completion: @escaping (Result<[Bookmark], Error>) -> Void) {
        guard Auth.auth().currentUser != nil else {
            completion(.failure(NSError.init(domain: "", code: 500, userInfo: ["message": "need login"])))
            return
        }

        db.collection("bookmarks")
            .order(by: "created_at", descending: true)
            .getDocuments() { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                guard let snapshot = snapshot else {
                    completion(.failure(NSError.init(domain: "", code: 500, userInfo: ["message": "no result"])))
                    return
                }

                let bookmarks = snapshot.documents.compactMap { Bookmark(dictionary: $0.data()) }
                completion(.success(bookmarks))
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

    static func execUpdateBookmarkComment(param: ExecUpdateBookmarkCommentParam, completion: @escaping (Result<HTTPSCallableResult?, Error>) -> Void) {
        guard Auth.auth().currentUser != nil else {
            completion(.failure(NSError.init(domain: "", code: 500, userInfo: ["message": "need login"])))
            return
        }

        functions.httpsCallable("execCreateOrUpdateBookmarkComment").call(param.toDict) { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            completion(.success(result))
        }
    }
}
