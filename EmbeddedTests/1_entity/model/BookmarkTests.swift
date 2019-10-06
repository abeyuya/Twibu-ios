//
//  BookmarkTests.swift
//  EmbeddedTests
//
//  Created by abeyuya on 2019/10/06.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import XCTest
import Embedded

class BookmarkTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testDecode() {
        let json = """
{
    "uid": "aaabbbb",
    "title": "title",
    "image_url": "https://hoge.com/image.png",
    "description": "description",
    "comment_count": 10,
    "created_at": 15000000,
    "updated_at": 1500000,
    "url": "https://hoge.com/article/1234",
    "category": ""
}
"""

        do {
            let result = try JSONDecoder().decode(
                Embedded.Bookmark.self,
                from: json.data(using: .utf8)!
            )
            assert(result.uid == "aaabbbb")
            assert(result.category == .unknown)
        } catch {
            assert(false, error.localizedDescription)
        }
    }
}
