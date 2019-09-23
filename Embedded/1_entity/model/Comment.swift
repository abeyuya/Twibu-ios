//
//  Comment.swift
//  Twibu
//
//  Created by abeyuya on 2019/06/21.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import Foundation

public struct Comment: Codable {
    public let id: String
    public let text: String
    public let user: User
    public let favorite_count: Int
    public let retweet_count: Int
    public let tweet_at: String
    public let created_at: Int?
    public let updated_at: Int?
    public let parsed_comment: [TextBlock]?
    public let has_comment: Bool?

    public struct User: Codable {
        public let twitter_user_id: String
        public let name: String
        public let profile_image_url: String
        public let screen_name: String
        public let verified: Bool?
    }

    public enum TextBlockType: String, Codable {
        case unknown = "unknown"
        case comment = "comment"
        case title = "title"
        case space = "space"
        case url = "url"
        case hashtag = "hashtag"
        case via = "via"
        case ignore_symbol = "ignore_symbol"
        case system_post = "system_post"
        case reply = "reply"
        case error = "error" // サーバ側で新しいtypeが追加された時に使う
    }

    public struct TextBlock: Codable {
        public let type: TextBlockType
        public let text: String

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            type = {
                guard let typeRawValue = try? container.decode(String.self, forKey: .type) else { return .error }
                guard let value = TextBlockType(rawValue: typeRawValue) else { return .error }
                return value
            }()
            text = try container.decode(String.self, forKey: .text)
        }
    }

    public var tweetUrl: URL? {
        let str = "https://twitter.com/\(user.screen_name)/status/\(id)"
        return URL(string: str)
    }
}

public extension Comment {
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
    public static func == (lhs: Comment, rhs: Comment) -> Bool {
        return lhs.id == rhs.id && lhs.updated_at == rhs.updated_at
    }
}

public extension Comment {
    static func buildFirestoreDebugLink(buid: String, cuid: String) -> URL? {
        let str = "https://console.firebase.google.com/project/twibu-c4d5a/database/firestore/data~2Fbookmarks~2F\(buid)~2Fcomments~2F\(cuid)"

        return URL(string: str)
    }
}