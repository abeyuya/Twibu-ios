//
//  CommentRepository.swift
//  Twibu
//
//  Created by abeyuya on 2019/06/21.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import FirebaseAuth
import FirebaseFirestore
import FirebaseFunctions
import Embedded

enum CommentRepositoryFirestore {
    static func fetchBookmarkComment(
        bookmarkUid: String,
        type: Repository.FetchType,
        completion: @escaping ((Repository.Response<[Comment]>) -> Void)
    ) {
        guard Auth.auth().currentUser != nil else {
            completion(.failure(.needFirebaseAuth("need firebase login")))
            return
        }

        CommentRepositoryFirestore.buildQuery(bookmarkUid: bookmarkUid, type: type)
            .getDocuments() { snapshot, error in
                if let error = error {
                    completion(.failure(.firestoreError(error.localizedDescription)))
                    return
                }

                guard let snapshot = snapshot else {
                    completion(.failure(.firestoreError("no result")))
                    return
                }

                let comments = snapshot.documents.compactMap { Comment(dictionary: $0.data()) }
                let result: Repository.Result<[Comment]> = {
                    guard let last = snapshot.documents.last else {
                        return Repository.Result<[Comment]>(
                            item: comments,
                            pagingInfo: nil,
                            hasMore: false
                        )
                    }

                    return Repository.Result<[Comment]>(
                        item: comments,
                        pagingInfo: RepositoryPagingInfo(lastSnapshot: last),
                        hasMore: !snapshot.documents.isEmpty
                    )
                }()

                completion(.success(result))
        }
    }

    private static func buildQuery(bookmarkUid: String, type: Repository.FetchType) -> Query {
        let q = TwibuFirebase.shared.firestore
            .collection("bookmarks")
            .document(bookmarkUid)
            .collection("comments")
            .order(by: "favorite_count", descending: true)

        switch type {
        case .new(let limit):
            return q.limit(to: limit)
        case .add(let (limit, info)):
            guard let d = info?.lastSnapshot as? DocumentSnapshot else {
                // スナップショットが無い場合は先頭から取得
                return q.limit(to: limit)
            }
            return q.start(afterDocument: d).limit(to: limit)
        }
    }

    //
    // NOTE: 更新後の全てのコメントを返却する
    //
    static func execUpdateBookmarkComment(
        bookmarkUid: String,
        title: String,
        url: String,
        completion: @escaping (Result<[Comment]>) -> Void
    ) {
        let param = [
            "bookmark_uid": bookmarkUid,
            "title": title,
            "url": url
        ]

        TwibuFirebase.shared.functions
            .httpsCallable("execCreateOrUpdateBookmarkComment")
            .call(param) { result, error in
                if let error = error {
                    completion(.failure(.firestoreError(error.localizedDescription)))
                    return
                }

                guard let res = result?.data as? [String: Any] else {
                    completion(.failure(.firestoreError("")))
                    return
                }

                guard let rawComments = res["comments"] as? [[String: Any]] else {
                    completion(.failure(.firestoreError("")))
                    return
                }

                let comments = rawComments.compactMap { Comment(dictionary: $0) }

                // NOTE: APIリミットエラーとかでも0件で返ってくる

                completion(.success(comments))
        }
    }
}
