//
//  CommentRepository.swift
//  Embedded
//
//  Created by abeyuya on 2019/09/23.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import Foundation

//public protocol CommentRepository {
//    static func fetchBookmarkComment(
//        bookmarkUid: String,
//        type: Repository.FetchType,
//        completion: @escaping ((Repository.Response<[Comment]>) -> Void)
//    )
//
//    private static func buildQuery(db: Firestore, bookmarkUid: String, type: Repository.FetchType) -> Query {
//        let q = db.collection("bookmarks")
//            .document(bookmarkUid)
//            .collection("comments")
//            .order(by: "favorite_count", descending: true)
//
//        switch type {
//        case .new(let limit):
//            return q.limit(to: limit)
//        case .add(let (limit, snapshot)):
//            if let s = snapshot {
//                return q.start(afterDocument: s).limit(to: limit)
//            } else {
//                // スナップショットが無い場合は先頭から取得
//                return q.limit(to: limit)
//            }
//        }
//    }
//
//    //
//    // NOTE: 検索で引っかかった分だけしか返さないので注意
//    //
//    static func execUpdateBookmarkComment(
//        functions: Functions,
//        bookmarkUid: String,
//        title: String,
//        url: String,
//        completion: @escaping (Result<[Comment]>) -> Void
//    ) {
//        let param = [
//            "bookmark_uid": bookmarkUid,
//            "title": title,
//            "url": url
//        ]
//
//        functions.httpsCallable("execCreateOrUpdateBookmarkComment").call(param) { result, error in
//            if let error = error {
//                completion(.failure(.firestoreError(error.localizedDescription)))
//                return
//            }
//
//            guard let res = result?.data as? [String: Any] else {
//                completion(.failure(.firestoreError("")))
//                return
//            }
//
//            guard let rawComments = res["comments"] as? [[String: Any]] else {
//                completion(.failure(.firestoreError("")))
//                return
//            }
//
//            let comments = rawComments.compactMap { Comment(dictionary: $0) }
//
//            // NOTE: APIリミットエラーとかでも0件で返ってくるので、0件はエラーとして扱う
//            if comments.isEmpty {
//                completion(.failure(.firestoreError("response comments is empty")))
//                return
//            }
//
//            completion(.success(comments))
//        }
//    }
//}
