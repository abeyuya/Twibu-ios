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
    let uid: String
    let title: String?
    let image_url: String?
    let description: String?
    let created_at: Int?
    let updated_at: Int?
    let url: Url

    struct Url: Codable {
        let url: String?
        let expanded_url: String?
        let display_url: String?
    }
}

extension Bookmark: Codable {
    init(dictionary: [String: Any]) throws {
        let dict: [String: Any] = {
            guard let createdAt = dictionary["created_at"] as? Timestamp,
                let updatedAt = dictionary["updated_at"] as? Timestamp else {
                    return dictionary
            }
            var newDict = dictionary
            newDict["created_at"] = createdAt.seconds
            newDict["updated_at"] = updatedAt.seconds
            return newDict
        }()

        self = try JSONDecoder().decode(
            Bookmark.self,
            from: JSONSerialization.data(withJSONObject: dict)
        )
    }
}

struct Comment {
    let id: String
    let text: String

    struct User: Codable {
        let twitter_user_id: String
        let name: String
        let profile_image_url: String
    }
}

extension Comment: Codable {
    init(dictionary: [String: Any]) throws {
        self = try JSONDecoder().decode(
            Comment.self,
            from: JSONSerialization.data(withJSONObject: dictionary)
        )
    }
}

final class BookmarkUtil {
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
        functions.httpsCallable("execUpdateBookmarkComment").call(data) { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            completion(.success(result))
        }
    }

    static func fetchBookmarkComment(bookmarkUid: String, completion: @escaping (Result<[Comment], Error>) -> Void) {
        guard Auth.auth().currentUser != nil else {
            completion(.failure(NSError.init(domain: "", code: 500, userInfo: ["message": "need login"])))
            return
        }

        db.collection("bookmarks").document(bookmarkUid).collection("comments").getDocuments() { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let snapshot = snapshot else {
                completion(.failure(NSError.init(domain: "", code: 500, userInfo: ["message": "no result"])))
                return
            }

            let comments = snapshot.documents.compactMap { try? Comment(dictionary: $0.data()) }
            completion(.success(comments))
        }
    }
}
