//
//  CommentDispatcher.swift
//  Twibu
//
//  Created by abeyuya on 2019/06/23.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import Foundation

struct CommentDispatcher {
    static func updateBookmarkComment(bookmarkUid: String, url: String) {
        let startLoadingAction = AddCommentsAction(
            bookmarkUid: bookmarkUid,
            comments: .loading([])
        )
        store.mDispatch(startLoadingAction)

        CommentRepository.execUpdateBookmarkComment(bookmarkUid: bookmarkUid, url: url) { result in
            switch result {
            case .failure(let error):
                let a = AddCommentsAction(
                    bookmarkUid: bookmarkUid,
                    comments: .faillure(error)
                )
                store.mDispatch(a)
            case .success(let comments):
                // TODO: 全件は取得できていないけど、comment_count更新する？
                let a = AddCommentsAction(
                    bookmarkUid: bookmarkUid,
                    comments: .success(comments ?? [])
                )
                store.mDispatch(a)

                if let count = comments?.count {
                    let a2 = UpdateBookmarkCommentCountAction(
                        bookmarkUid: bookmarkUid,
                        commentCount: count
                    )
                    store.mDispatch(a2)
                }
            }
        }
    }

    static func fetchComments(buid: String, type: Repository.FetchType = .new) {
        let startLoadingAction = AddCommentsAction(
            bookmarkUid: buid,
            comments: .loading([])
        )
        store.mDispatch(startLoadingAction)

        CommentRepository.fetchBookmarkComment(bookmarkUid: buid, type: type) { result in
            switch result {
            case .success(let comments):
                let a = AddCommentsAction(
                    bookmarkUid: buid,
                    comments: .success(comments)
                )
                store.mDispatch(a)
            case .failure(let error):
                let a = AddCommentsAction(
                    bookmarkUid: buid,
                    comments: .faillure(error)
                )
                store.mDispatch(a)
            }
        }
    }
}
