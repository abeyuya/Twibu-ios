//
//  Comment.swift
//  Twibu
//
//  Created by abeyuya on 2019/06/21.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import Foundation
import FirebaseFirestore

struct Comment {
    let id: String
    let text: String
    let user: User
    let favorite_count: Int
    let retweet_count: Int
    let tweet_at: String
    let created_at: Int?
    let updated_at: Int?

    struct User: Codable {
        let twitter_user_id: String
        let name: String
        let profile_image_url: String
        let screen_name: String
//        let verified: Bool?
    }
}

extension Comment: Codable {
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
                Comment.self,
                from: JSONSerialization.data(withJSONObject: dict)
            )
        } catch {
            print("decodeに失敗しました", dict)
            return nil
        }
    }
}

