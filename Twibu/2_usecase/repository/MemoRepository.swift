//
//  MemoRepository.swift
//  Embedded
//
//  Created by abeyuya on 2019/08/02.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import Embedded
import FirebaseFirestore
import Promises

enum MemoRepository {
    static let db = TwibuFirebase.shared.firestore

    static func fetchMemoBookmarks(
        userUid: String,
        type: Repository.FetchType,
        completion: @escaping (Result<Repository.Result<[MemoReducer.Info]>, TwibuError>) -> Void
    ) {
        let query: Query = {
            switch type {
            case .new(let limit):
                return db.collection("users")
                    .document(userUid)
                    .collection("memo")
                    .order(by: "created_at", descending: true)
                    .limit(to: limit)
            case .add(let (limit, info)):
                guard let last = info?.lastSnapshot as? DocumentSnapshot else {
                    return db.collection("users")
                        .document(userUid)
                        .collection("memo")
                        .order(by: "created_at", descending: true)
                        .limit(to: limit)
                }

                return db.collection("users")
                    .document(userUid)
                    .collection("memo")
                    .order(by: "created_at", descending: true)
                    .start(afterDocument: last)
                    .limit(to: limit)
            }
        }()

        query.getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(.firestoreError(error.localizedDescription)))
                return
            }

            guard let snapshot = snapshot else {
                completion(.failure(.firestoreError("no result")))
                return
            }

            let memos = snapshot.documents.compactMap { Memo(dictionary: $0.data()) }

            execConcurrentFetch(memos: memos) { info in
                let last = snapshot.documents.last
                let result = Repository.Result(
                    item: info,
                    pagingInfo: RepositoryPagingInfo(lastSnapshot: last),
                    hasMore: last == nil ? false : true
                )

                completion(.success(result))
            }
        }
    }

    private static func execConcurrentFetch(memos: [Memo], completion: @escaping ([MemoReducer.Info]) -> Void) {
        let tasks = memos.map { m in
            return Promise<(MemoReducer.Info?)>(on: .global()) { fulfill, reject in
                m.bookmark_ref.getDocument { snapshot, error in
                    if let error = error {
                        Logger.print(error)
                        reject(error)
                        return
                    }

                    guard let snapshot = snapshot, let dict = snapshot.data() else {
                        Logger.print("snapshotが取れず...")
                        fulfill(nil)
                        return
                    }

                    guard let b = Bookmark(dictionary: dict) else {
                        Logger.print("bookmark decode できず")
                        fulfill(nil)
                        return
                    }

                    fulfill(MemoReducer.Info(memo: m, bookmark: b))
                }
            }
        }

        Promises.all(tasks)
            .then { results in
                let filterd = results.compactMap { $0 }
                completion(filterd)
            }
            .catch { error in
                Logger.print(error)
                completion([])
            }
    }

    public static func fetchMemo(
        userUid: String,
        bookmarkUid: String,
        completion: @escaping (Result<Memo, TwibuError>) -> Void
    ) {
        db.collection("users")
            .document(userUid)
            .collection("memo")
            .document(bookmarkUid)
            .getDocument() { snapshot, error in
                if let error = error {
                    let e = TwibuError.firestoreError(error.localizedDescription)
                    completion(.failure(e))
                    return
                }

                guard snapshot?.exists ?? false else {
                    completion(.failure(TwibuError.firestoreError("古いメモなし(別にエラーではない)")))
                    return
                }

                guard let dict = snapshot?.data(), let memo = Memo(dictionary: dict) else {
                    completion(.failure(TwibuError.firestoreError("memo decode失敗")))
                    return
                }

                completion(.success(memo))
        }
    }

    public static func saveMemo(
        userUid: String,
        bookmarkUid: String,
        memo: String,
        isNew: Bool,
        completion: @escaping (Result<Void, TwibuError>) -> Void
    ) {
        let ref = db.collection("users")
            .document(userUid)
            .collection("memo")
            .document(bookmarkUid)

        let data: [String : Any] = [
            "bookmark_ref": db.collection("bookmarks").document(bookmarkUid),
            "memo": memo,
            "updated_at": FieldValue.serverTimestamp()
        ]

        if isNew {
            let newMemoData = data.merging(["created_at": FieldValue.serverTimestamp()]) { $1 }
            ref.setData(newMemoData) { error in
                if let error = error {
                    let e = TwibuError.firestoreError(error.localizedDescription)
                    completion(.failure(e))
                    return
                }

                completion(.success(Void()))
            }
            return
        }

        ref.updateData(data) { error in
            if let error = error {
                let e = TwibuError.firestoreError(error.localizedDescription)
                completion(.failure(e))
                return
            }

            completion(.success(Void()))
        }
    }

    public static func deleteMemo(
        userUid: String,
        bookmarkUid: String,
        completion: @escaping (Result<Void, TwibuError>) -> Void
    ) {
        let ref = TwibuFirebase.shared.firestore
            .collection("users")
            .document(userUid)
            .collection("memo")
            .document(bookmarkUid)

        ref.delete { error in
            if let error = error {
                let e = TwibuError.firestoreError(error.localizedDescription)
                completion(.failure(e))
                return
            }

            completion(.success(Void()))
        }
    }
}
