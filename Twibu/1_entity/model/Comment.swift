//
//  Comment.swift
//  Twibu
//
//  Created by abeyuya on 2019/06/21.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import Foundation
import FirebaseFirestore

struct Comment: TwibuFirestoreCodable {
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
        let verified: Bool?
    }

    var tweetUrl: URL? {
        let str = "https://twitter.com/\(user.screen_name)/status/\(id)"
        return URL(string: str)
    }
}

extension Comment {
    func replacedText(title: String) -> String {
        let t = Comment.urlReplacedText(text: text)
        return Comment.titleReplacedText(text: t, title: title)
    }

    static func titleReplacedText(text: String, title: String) -> String {
        guard let replaceStr = text.pickupDeplicateString(target: title) else {
            return text
        }

        if replaceStr.count < title.count / 2 {
            // 半分以上が合致してないなら置換しない
            return text
        }

        guard let range = text.range(of: replaceStr) else {
            return text
        }

        return text.replacingCharacters(in: range, with: "{title}")
    }

    private static func urlReplacedText(text: String) -> String {
        let pattern = "(?i)https?://(?:www\\.)?\\S+(?:/|\\b)"
        let urls = text.capture(pattern: pattern, group: [0])

        guard let url = urls.first else { return text }
        guard let range = text.range(of: url) else { return text }

        let new = text.replacingCharacters(in: range, with: "{url}")
        return urlReplacedText(text: new)
    }
}

extension Comment {
    // 古いものを新しいもので置き換えつつ合体する
    static func merge(base: [Comment], add: [Comment]) -> [Comment] {
        var result = base

        add.forEach { b in
            if let i = result.firstIndex(where: { $0.id == b.id }) {
                result[i] = b
                return
            }
            result.append(b)
        }

        return result
    }
}
