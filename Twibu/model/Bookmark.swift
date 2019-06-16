//
//  Bookmark.swift
//  Twibu
//
//  Created by abeyuya on 2019/06/17.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import FirebaseAuth
import FirebaseFirestore
import FirebaseFunctions

struct Bookmark {
    var rawData: [String: Any]

    var title: String? {
        let ogp = rawData["ogp"] as? [String: Any]
        return ogp?["title"] as? String
    }

//    var url: String? {
//        return rawData["ogp"]?["url"] as? String
//    }
}

final class BookmarkUtil {
    private static let db = Firestore.firestore()

    static func fetchBookmark(completion: @escaping (Result<[Bookmark], Error>) -> Void) {
        guard Auth.auth().currentUser != nil else {
            completion(.failure(NSError.init(domain: "", code: 500, userInfo: ["message": "need login"])))
            return
        }

        db.collection("bookmarks").getDocuments() { documents, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let documents = documents else {
                completion(.failure(NSError.init(domain: "", code: 500, userInfo: ["message": "no result"])))
                return
            }

            let bookmarks = documents.documents.map { Bookmark(rawData: $0.data()) }
            completion(.success(bookmarks))
        }
    }
}
