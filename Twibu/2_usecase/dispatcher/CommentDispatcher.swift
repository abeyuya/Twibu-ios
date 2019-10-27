//
//  CommentDispatcher.swift
//  Twibu
//
//  Created by abeyuya on 2019/06/23.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import Foundation
import Embedded

public enum CommentDispatcher {
    private static func updateBookmarkComment(
        bookmarkUid: String,
        title: String,
        url: String,
        completion: @escaping (Result<[Comment], TwibuError>) -> Void
    ) {
        updateState(buid: bookmarkUid, s: .loading)
        CommentRepositoryFirestore.execUpdateBookmarkComment(
            bookmarkUid: bookmarkUid,
            title: title,
            url: url
        ) { res in
            switch res {
            case .success(let comments):
                do {
                    let result = Repository.Result<[Comment]>(
                        item: comments,
                        pagingInfo: nil,
                        hasMore: false
                    )
                    let a = CommentReducer.Actions.Add(
                        bookmarkUid: bookmarkUid,
                        comments: result
                    )
                    store.mDispatch(a)
                }

                do {
                    // store上のデータ書き換え
                    let a = CategoryReducer.Actions.UpdateBookmarkCommentCountIfOver(
                        bookmarkUid: bookmarkUid,
                        commentCount: comments.count
                    )
                    store.mDispatch(a)
                }

                updateState(buid: bookmarkUid, s: .success)

            case .failure(let error):
                Logger.print(error.displayMessage)
                // NOTE: 失敗しても何もなかったことにする
                updateState(buid: bookmarkUid, s: .notYetLoading)
            }

            completion(res)
        }
    }

    public static func fetchComments(buid: String, type: Repository.FetchType) {
        switch type {
        case .add:
            updateState(buid: buid, s: .additionalLoading)
        case .new:
            updateState(buid: buid, s: .loading)
        }

        CommentRepositoryFirestore.fetchBookmarkComment(bookmarkUid: buid, type: type) { result in
            switch result {
            case .failure(let e):
                updateState(buid: buid, s: .failure(e))
            case .success(let res):
                do {
                    let a = CommentReducer.Actions.Add(
                        bookmarkUid: buid,
                        comments: res
                    )
                    store.mDispatch(a)
                }

                do {
                    // store上のデータ書き換え
                    let a = CategoryReducer.Actions.UpdateBookmarkCommentCountIfOver(
                        bookmarkUid: buid,
                        commentCount: res.item.count
                    )
                    store.mDispatch(a)
                }

                updateState(buid: buid, s: .success)
            }
        }
    }

    public static func updateAndFetchComments(
        buid: String,
        title: String,
        url: String,
        type: Repository.FetchType
    ) {
        updateBookmarkComment(
            bookmarkUid: buid,
            title: title,
            url: url
        ) { result in
            switch result {
            case .failure(let error):
                Logger.print(error)
                break
            case .success(_):
                break
            }

            fetchComments(buid: buid, type: type)
        }
    }

    private static func updateState(buid: String, s: Repository.ResponseState) {
        let a = CommentReducer.Actions.UpdateState(bookmarkUid: buid, state: s)
        store.mDispatch(a)
    }
}
