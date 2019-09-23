//
//  CommentDispatcher.swift
//  Twibu
//
//  Created by abeyuya on 2019/06/23.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import Foundation
import Embedded
import FirebaseFunctions
import FirebaseFirestore

enum CommentDispatcher {
    private static func updateBookmarkComment(
        functions: Functions,
        bookmarkUid: String,
        title: String,
        url: String,
        completion: @escaping (Result<[Comment]>) -> Void
    ) {
        let dummyResult = FirestoreRepo.Result<[Comment]>(item: [], pagingInfo: nil, hasMore: false)
        let startLoadingAction = AddCommentsAction(
            bookmarkUid: bookmarkUid,
            comments: .loading(dummyResult)
        )
        store.mDispatch(startLoadingAction)

        CommentRepositoryFirestore.execUpdateBookmarkComment(
            functions: functions,
            bookmarkUid: bookmarkUid,
            title: title,
            url: url
        ) { res in
            switch res {
            case .success(let comments):
                let result = FirestoreRepo.Result<[Comment]>(
                    item: comments,
                    pagingInfo: nil,
                    hasMore: true
                )
                let commentsResponse = Repository.Response<[Comment]>.success(result)
                let a = AddCommentsAction(
                    bookmarkUid: bookmarkUid,
                    comments: commentsResponse
                )
                store.mDispatch(a)

                // store上のデータ書き換え
                let a2 = UpdateBookmarkCommentCountIfOverAction(
                    bookmarkUid: bookmarkUid,
                    commentCount: comments.count
                )
                store.mDispatch(a2)

            case .failure(let error):
                Logger.print(error.displayMessage)

                // NOTE: 失敗しても何もなかったことにする
                let a = AddCommentsAction(
                    bookmarkUid: bookmarkUid,
                    comments: .notYetLoading
                )
                store.mDispatch(a)
            }

            completion(res)
        }
    }

    static func fetchComments(db: Firestore, buid: String, type: FirestoreRepo.FetchType) {
        let result = FirestoreRepo.Result<[Comment]>(item: [], pagingInfo: nil, hasMore: false)
        let startLoadingAction = AddCommentsAction(
            bookmarkUid: buid,
            comments: .loading(result)
        )
        store.mDispatch(startLoadingAction)

        CommentRepositoryFirestore.fetchBookmarkComment(db: db, bookmarkUid: buid, type: type) { result in
            let a = AddCommentsAction(
                bookmarkUid: buid,
                comments: result
            )
            store.mDispatch(a)

            // store上のデータ書き換え
            if let count = result.item?.count {
                let a2 = UpdateBookmarkCommentCountIfOverAction(
                    bookmarkUid: buid,
                    commentCount: count
                )
                store.mDispatch(a2)
            }
        }
    }

    static func updateAndFetchComments(
        db: Firestore,
        functions: Functions,
        buid: String,
        title: String,
        url: String,
        type: FirestoreRepo.FetchType
    ) {
        updateBookmarkComment(functions: functions, bookmarkUid: buid, title: title, url: url) { result in
            switch result {
            case .failure(let error):
                Logger.print(error)
                break
            case .success(_):
                break
            }

            fetchComments(db: db, buid: buid, type: type)
        }
    }
}
