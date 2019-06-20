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

        db.collection("bookmarks").getDocuments() { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let snapshot = snapshot else {
                completion(.failure(NSError.init(domain: "", code: 500, userInfo: ["message": "no result"])))
                return
            }

            let bookmarks = snapshot.documents.compactMap { try? Bookmark(dictionary: $0.data()) }
            completion(.success(bookmarks))
        }
    }

    static func execUpdateBookmarkComment(bookmarkUid: String, completion: @escaping (Result<HTTPSCallableResult?, Error>) -> Void) {
        guard Auth.auth().currentUser != nil else {
            completion(.failure(NSError.init(domain: "", code: 500, userInfo: ["message": "need login"])))
            return
        }

        let data: [String: String] = ["bookmark_uid": bookmarkUid]
        functions.httpsCallable("execCreateOrUpdateBookmarkComment").call(data) { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            completion(.success(result))
        }
    }
}
