//
//  CommentDispatcher.swift
//  Twibu
//
//  Created by abeyuya on 2019/06/23.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import Foundation

struct CommentDispatcher {
    static func updateBookmarkComment(bookmarkUid: String, title: String, url: String, oldCount: Int) {
        let result = Repository.Result<[Comment]>(item: [], lastSnapshot: nil, hasMore: false)
        let startLoadingAction = AddCommentsAction(
            bookmarkUid: bookmarkUid,
            comments: .loading(result)
        )
        store.mDispatch(startLoadingAction)

        CommentRepository.execUpdateBookmarkComment(bookmarkUid: bookmarkUid, title: title, url: url) { result in
            let a = AddCommentsAction(
                bookmarkUid: bookmarkUid,
                comments: result
            )
            store.mDispatch(a)

            if let count = result.item?.count, oldCount < count {
                // store上のデータ書き換え
                let a2 = UpdateBookmarkCommentCountAction(
                    bookmarkUid: bookmarkUid,
                    commentCount: count
                )
                store.mDispatch(a2)
            }
        }
    }

    static func fetchComments(buid: String, type: Repository.FetchType) {
        let result = Repository.Result<[Comment]>(item: [], lastSnapshot: nil, hasMore: false)
        let startLoadingAction = AddCommentsAction(
            bookmarkUid: buid,
            comments: .loading(result)
        )
        store.mDispatch(startLoadingAction)

        CommentRepository.fetchBookmarkComment(bookmarkUid: buid, type: type) { result in
            let a = AddCommentsAction(
                bookmarkUid: buid,
                comments: result
            )
            store.mDispatch(a)
        }
    }
}
