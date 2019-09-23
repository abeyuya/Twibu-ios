//
//  CommentTests.swift
//  TwibuTests
//
//  Created by abeyuya on 2019/06/26.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import XCTest
import Embedded
@testable import Twibu

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
}