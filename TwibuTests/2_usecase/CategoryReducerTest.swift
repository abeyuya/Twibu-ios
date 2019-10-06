//
//  CategoryReducerTest.swift
//  TwibuTests
//
//  Created by abeyuya on 2019/10/06.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import XCTest
import Embedded
@testable import Twibu

class CategoryReducerTest: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testUpdateBookmarkCommentCountIfOver() {
        let b = buildBookmark(key: "1")

        do {
            let r = Repository.Result<[Bookmark]>(item: [b], pagingInfo: nil, hasMore: false)
            let a = CategoryReducer.Actions.AddBookmarks(category: .it, result: r)
            store.dispatch(a)
            guard let rr = store.state.category.result[.it] else {
                assert(false)
                return
            }
            assert(rr.item == [b])
        }

        do {
            let a = CategoryReducer.Actions.UpdateBookmarkCommentCountIfOver(bookmarkUid: b.uid, commentCount: 1)
            store.dispatch(a)
            guard let rr = store.state.category.result[.it] else {
                assert(false)
                return
            }
            guard let c = rr.item.first else {
                assert(false)
                return
            }
            assert(c.comment_count == 10)
        }

        do {
            let a = CategoryReducer.Actions.UpdateBookmarkCommentCountIfOver(bookmarkUid: b.uid, commentCount: 130)
            store.dispatch(a)
            guard let rr = store.state.category.result[.it] else {
                assert(false)
                return
            }
            guard let c = rr.item.first else {
                assert(false)
                return
            }
            assert(c.comment_count == 130)
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
