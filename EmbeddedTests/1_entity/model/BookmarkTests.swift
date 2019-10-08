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

    func testMerge() {
        let a = [buildBookmark(key: "1"), buildBookmark(key: "2")]
        do {
            let result = a.merge(add: a) { $0.uid == $1.uid }
            assert(result == a)
        }

        let b = [buildBookmark(key: "3"), buildBookmark(key: "4")]
        do {
            let result = a.merge(add: b) { $0.uid == $1.uid }
            assert(result == (a + b))
        }

        do {
            let a2 = a.merge(add: b) { $0.uid == $1.uid }
            let result = a2.merge(add: b) { $0.uid == $1.uid }
            assert(result == a2)
        }

        do {
            let a2 = a.merge(add: b) { $0.uid == $1.uid }
            let strong = buildBookmark(key: "1", strongTitle: "title-strong-1")
            let result = a2.merge(add: [strong]) { $0.uid == $1.uid }
            assert(result.map { $0.uid } == ["uid-1", "uid-2", "uid-3", "uid-4"])
            assert(result.map { $0.title } == ["title-strong-1", "title-2", "title-3", "title-4"])
        }
    }

    private func buildBookmark(key: String, strongTitle: String? = nil) -> Bookmark {
        let json = """
{
    "uid": "uid-\(key)",
    "title": "\(strongTitle ?? "title-\(key)")",
    "image_url": "https://hoge.com/image.png",
    "description": "description",
    "comment_count": 10,
    "created_at": 15000000,
    "updated_at": 1500000,
    "url": "https://hoge.com/article/1234",
    "category": "it"
}
"""
        return try! JSONDecoder().decode(
            Embedded.Bookmark.self,
            from: json.data(using: .utf8)!
        )
    }
}
