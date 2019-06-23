//
//  Bookmark.swift
//  Twibu
//
//  Created by abeyuya on 2019/06/17.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import Foundation
import FirebaseFirestore

struct Bookmark: TwibuFirestoreRecord {
    let uid: String
    let title: String?
    let image_url: String?
    let description: String?
    let comment_count: Int?
    let created_at: Int?
    let updated_at: Int?
    let url: String
}

extension Bookmark {
    init(_ bookmark: Bookmark, commentCount: Int) {
        uid = bookmark.uid
        title = bookmark.title
        image_url = bookmark.image_url
        description = bookmark.description
        comment_count = commentCount // これだけ差し替えている
        created_at = bookmark.created_at
        updated_at = bookmark.updated_at
        url = bookmark.url
    }
}

extension Bookmark: Codable {
    init?(dictionary: [String: Any]) {
        let dict: [String: Any] = {
            var newDict = dictionary

            if let createdAt = dictionary["created_at"] as? Timestamp {
                newDict["created_at"] = createdAt.seconds
            } else {
                newDict.removeValue(forKey: "created_at")
            }

            if let updatedAt = dictionary["updated_at"] as? Timestamp {
                newDict["updated_at"] = updatedAt.seconds
            } else {
                newDict.removeValue(forKey: "updated_at")
            }
            return newDict
        }()

        do {
            self = try JSONDecoder().decode(
                Bookmark.self,
                from: JSONSerialization.data(withJSONObject: dict)
            )
        } catch {
            print("Bookmarkのdecodeに失敗しました", dict)
            return nil
        }
    }
}
