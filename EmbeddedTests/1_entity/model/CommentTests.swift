//
//  CommentTests.swift
//  TwibuTests
//
//  Created by abeyuya on 2019/06/26.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import XCTest
import Embedded

class CommentTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testJsonDecodeSuccessIfIncludeBadInvalidType() {
        let json = """
{
    "id": "aaabbbb",
    "text": "aaabbbb",
    "user": {
        "twitter_user_id": "aaa",
        "name": "aaa",
        "profile_image_url": "aaa",
        "screen_name": "aaa",
        "verified": false
    },
    "favorite_count": 10,
    "retweet_count": 10,
    "tweet_at": "2019/09/09",
    "tweet_at": "2019/09/09",
    "parsed_comment": [
        {
            "type": "url",
            "text": "hogehoge"
        },
        {
            "type": "invalid_type",
            "text": "hogehoge"
        }
    ]
}
"""

        do {
            let result = try JSONDecoder().decode(
                Embedded.Comment.self,
                from: json.data(using: .utf8)!
            )
            assert(result.id == "aaabbbb")
            assert(result.parsed_comment![0].type == .url)
            assert(result.parsed_comment![1].type == .error)
        } catch {
            assert(false, error.localizedDescription)
        }
    }

    func testMerge() {
        let a = [buildComment(key: "1"), buildComment(key: "2")]
        do {
            let result = a.merge(add: a) { $0.id == $1.id }
            assert(result == a)
        }

        let b = [buildComment(key: "3"), buildComment(key: "4")]
        do {
            let result = a.merge(add: b) { $0.id == $1.id }
            assert(result == (a + b))
        }

        do {
            let a2 = a.merge(add: b) { $0.id == $1.id }
            let result = a2.merge(add: b) { $0.id == $1.id }
            assert(result == a2)
        }

        do {
            let a2 = a.merge(add: b) { $0.id == $1.id }
            let strong = buildComment(key: "1", strongText: "text-strong-1")
            let result = a2.merge(add: [strong]) { $0.id == $1.id }
            assert(result.map { $0.id } == ["id-1", "id-2", "id-3", "id-4"])
            assert(result.map { $0.text } == ["text-strong-1", "text-2", "text-3", "text-4"])
        }
    }

    private func buildComment(key: String, strongText: String? = nil) -> Comment {
        let json = """
{
    "id": "id-\(key)",
    "text": "\(strongText ?? "text-\(key)")",
    "user": {
        "twitter_user_id": "aaa",
        "name": "aaa",
        "profile_image_url": "aaa",
        "screen_name": "aaa",
        "verified": false
    },
    "favorite_count": 10,
    "retweet_count": 10,
    "tweet_at": "2019/09/09",
    "tweet_at": "2019/09/09",
    "parsed_comment": [
        {
            "type": "url",
            "text": "hogehoge"
        },
        {
            "type": "invalid_type",
            "text": "hogehoge"
        }
    ]
}
"""
        return try! JSONDecoder().decode(
            Embedded.Comment.self,
            from: json.data(using: .utf8)!
        )
    }
}
