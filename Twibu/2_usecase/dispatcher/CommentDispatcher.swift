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
        store.dispatch(startLoadingAction)

        let param = CommentRepository.ExecUpdateBookmarkCommentParam(bookmarkUid: bookmarkUid, url: url)
        CommentRepository.execUpdateBookmarkComment(param: param) { result in
            switch result {
            case .failure(let error):
                let a = AddCommentsAction(
                    bookmarkUid: bookmarkUid,
                    comments: .faillure(error)
                )
                store.dispatch(a)
            case .success(let comments):
                // TODO: 実際には全件取得しているわけではないので、successにするとマズイかも？
                let a = AddCommentsAction(
                    bookmarkUid: bookmarkUid,
                    comments: .success(comments ?? [])
                )
                store.dispatch(a)

                if let count = comments?.count {
                    let a2 = UpdateBookmarkCommentCountAction(
                        bookmarkUid: bookmarkUid,
                        commentCount: count
                    )
                    store.dispatch(a2)
                }
            }
        }
    }
}
