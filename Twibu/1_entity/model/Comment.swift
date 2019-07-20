//
//  Comment.swift
//  Twibu
//
//  Created by abeyuya on 2019/06/21.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import Foundation
import FirebaseFirestore
import Embedded

struct Comment: TwibuFirestoreCodable {
    let id: String
    let text: String
    let user: User
    let favorite_count: Int
    let retweet_count: Int
    let tweet_at: String
    let created_at: Int?
    let updated_at: Int?
    let parsed_comment: [TextBlock]?
    let has_comment: Bool?

    struct User: Codable {
        let twitter_user_id: String
        let name: String
        let profile_image_url: String
        let screen_name: String
        let verified: Bool?
    }

    enum TextBlockType: String, Codable {
        case unknown = "unknown"
        case comment = "comment"
        case title = "title"
        case space = "space"
        case url = "url"
        case hashtag = "hashtag"
        case via = "via"
        case ignore_symbol = "ignore_symbol"
        case reply = "reply"
        case error = "error" // サーバ側で新しいtypeが追加された時に使う
    }

    struct TextBlock: Codable {
        var type: TextBlockType = .error
        let text: String
    }

    var tweetUrl: URL? {
        let str = "https://twitter.com/\(user.screen_name)/status/\(id)"
        return URL(string: str)
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

    static func isEqual(a: [Comment], b: [Comment]) -> Bool {
        if a.count != b.count {
            return false
        }

        let notEqual = a.first(where: { ac in
            if let same = b.first(where: { bc in bc.id == ac.id }) {
                return ac != same
            }
            return false
        })

        return notEqual == nil
    }
}

extension Comment: Equatable {
    static func == (lhs: Comment, rhs: Comment) -> Bool {
        return lhs.id == rhs.id && lhs.updated_at == rhs.updated_at
    }
}

extension Comment {
    static func buildFirestoreDebugLink(buid: String, cuid: String) -> URL? {
        let str = "https://console.firebase.google.com/project/twibu-c4d5a/database/firestore/data~2Fbookmarks~2F\(buid)~2Fcomments~2F\(cuid)"

        return URL(string: str)
    }
}
