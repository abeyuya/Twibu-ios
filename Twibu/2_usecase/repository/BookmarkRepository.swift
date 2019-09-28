//
//  BookmarkRepository.swift
//  Twibu
//
//  Created by abeyuya on 2019/06/21.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import Embedded
import FirebaseFirestore
import Promises

enum BookmarkRepository {
    static let db = TwibuFirebase.shared.firestore

    static func fetchBookmark(
        category: Embedded.Category,
        uid: String,
        type: Repository.FetchType,
        commentCountOffset: Int,
        completion: @escaping (Repository.Response<[Bookmark]>) -> Void
    ) {
        if category == .timeline {
            fetchTimelineBookmarks(uid: uid, type: type, completion: completion)
            return
        }

        if category == .memo {
            fetchMemoBookmarks(uid: uid, type: type, completion: completion)
            return
        }

        buildQuery(category: category, type: type).getDocuments() { snapshot, error in
            if let error = error {
                completion(.failure(.firestoreError(error.localizedDescription)))
                return
            }

            guard let snapshot = snapshot else {
                completion(.failure(.firestoreError("no result")))
                return
            }

            let item: [Bookmark] = {
                let b = snapshot.documents.compactMap { Bookmark(dictionary: $0.data()) }
                let filtered: [Bookmark] = {
                    var f = b.filter { $0.comment_count ?? 0 >= commentCountOffset }

                    switch category {
                    case .all:
                        f = f.filter { $0.category != .unknown }
                    default:
                        break
                    }

                    return f
                }()
                return filterOut(bookmarks: filtered)
            }()

            let result: Repository.Result<[Bookmark]> = {
                guard let last = snapshot.documents.last else {
                    return Repository.Result(
                        item: item,
                        pagingInfo: nil,
                        hasMore: false
                    )
                }

                return Repository.Result(
                    item: item,
                    pagingInfo: RepositoryPagingInfo(lastSnapshot: last),
                    hasMore: !snapshot.documents.isEmpty
                )
            }()

            completion(.success(result))
        }
    }
}

private extension BookmarkRepository {
    static private func buildQuery(category: Embedded.Category, type: Repository.FetchType) -> Query {
        switch category {
        case .all:
            switch type {
            case .new(let limit):
                return db.collection("bookmarks")
                    .order(by: "created_at", descending: true)
                    .limit(to: limit)
            case .add(let (limit, info)):
                guard let d = info?.lastSnapshot as? DocumentSnapshot else {
                    return db.collection("bookmarks")
                        .order(by: "created_at", descending: true)
                        .limit(to: limit)
                }
                return db.collection("bookmarks")
                    .order(by: "created_at", descending: true)
                    .start(afterDocument: d)
                    .limit(to: limit)
            }
        default:
            switch type {
            case .new(let limit):
                return db.collection("bookmarks")
                    .whereField("category", isEqualTo: category.rawValue)
                    .order(by: "created_at", descending: true)
                    .limit(to: limit)
            case .add(let (limit, info)):
                guard let d = info?.lastSnapshot as? DocumentSnapshot else {
                    return db.collection("bookmarks")
                        .whereField("category", isEqualTo: category.rawValue)
                        .order(by: "created_at", descending: true)
                        .limit(to: limit)
                }
                return db.collection("bookmarks")
                    .whereField("category", isEqualTo: category.rawValue)
                    .order(by: "created_at", descending: true)
                    .start(afterDocument: d)
                    .limit(to: limit)
            }
        }
    }

    private static func fetchTimelineBookmarks(
        uid: String,
        type: Repository.FetchType,
        completion: @escaping (Repository.Response<[Bookmark]>) -> Void
    ) {
        let query: Query = {
            switch type {
            case .new(let limit):
                return db.collection("users")
                    .document(uid)
                    .collection("timeline")
                    .order(by: "post_at", descending: true)
                    .limit(to: limit)
            case .add(let (limit, info)):
                guard let d = info?.lastSnapshot as? DocumentSnapshot else {
                    return db.collection("users")
                        .document(uid)
                        .collection("timeline")
                        .order(by: "post_at", descending: true)
                        .limit(to: limit)
                }
                return db.collection("users")
                    .document(uid)
                    .collection("timeline")
                    .order(by: "post_at", descending: true)
                    .start(afterDocument: d)
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

            let timelines = snapshot.documents.compactMap { Timeline(dictionary: $0.data()) }

            execConcurrentFetch(timelines: timelines) { bookmarks in
                let last = snapshot.documents.last
                let result = Repository.Result(
                    item: bookmarks,
                    pagingInfo: RepositoryPagingInfo(lastSnapshot: last),
                    hasMore: last == nil ? false : true
                )
                completion(.success(result))
            }
        }
    }

    private static func execConcurrentFetch(timelines: [Timeline], completion: @escaping ([Bookmark]) -> Void) {
        let tasks = timelines.map { t in
            return Promise<(Bookmark?, Int)>(on: .global()) { fulfill, reject in
                t.bookmark_ref.getDocument { snapshot, error in
                    if let error = error {
                        Logger.print(error)
                        reject(error)
                        return
                    }

                    guard let snapshot = snapshot, let dict = snapshot.data() else {
                        Logger.print("snapshotが取れず...")
                        fulfill((nil, 0))
                        return
                    }

                    guard let b = Bookmark(dictionary: dict) else {
                        Logger.print("bookmark decode できず")
                        fulfill((nil, 0))
                        return
                    }

                    if filterOut(bookmarks: [b]).isEmpty {
                        fulfill((nil, 0))
                        return
                    }

                    fulfill((b, t.post_at))
                }
            }
        }

        Promises.all(tasks)
            .then { results in
                let sortedBookmarks = results
                    .filter { $0.0 != nil }
                    .sorted(by: { $0.1 > $1.1 })
                    .compactMap { $0.0 }
                completion(sortedBookmarks)
            }
            .catch { error in
                Logger.print(error)
                completion([])
            }
    }

    private static let filterOutDomainPattern = [
        "anond.hatelabo.jp",
        "b.hatena.ne.jp",
        "htn.to"
    ]

    private static func filterOut(bookmarks: [Bookmark]) -> [Bookmark] {
        return bookmarks.filter { b in
            guard let url = URL(string: b.url) else { return true }

            let filterOutDomain = filterOutDomainPattern.first {
                guard let regex = try? NSRegularExpression(pattern: $0),
                    let host = url.host else { return false }

                if regex.firstMatch(
                    in: host,
                    options: .anchored,
                    range: NSRange(location: 0, length: host.count)
                ) != nil { return true }

                return false
            }

            return filterOutDomain == nil
        }
    }

    private static func fetchMemoBookmarks(
        uid: String,
        type: Repository.FetchType,
        completion: @escaping (Repository.Response<[Bookmark]>) -> Void
    ) {
        let query: Query = {
            switch type {
            case .new(let limit):
                return db.collection("users")
                    .document(uid)
                    .collection("memo")
                    .order(by: "created_at", descending: true)
                    .limit(to: limit)
            case .add(let (limit, info)):
                guard let last = info?.lastSnapshot as? DocumentSnapshot else {
                    return db.collection("users")
                        .document(uid)
                        .collection("memo")
                        .order(by: "created_at", descending: true)
                        .limit(to: limit)
                }

                return db.collection("users")
                    .document(uid)
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

            execConcurrentFetch(memos: memos) { bookmarks in
                let last = snapshot.documents.last
                let result = Repository.Result(
                    item: bookmarks,
                    pagingInfo: RepositoryPagingInfo(lastSnapshot: last),
                    hasMore: last == nil ? false : true
                )

                completion(.success(result))
            }
        }
    }

    private static func execConcurrentFetch(memos: [Memo], completion: @escaping ([Bookmark]) -> Void) {
        let tasks = memos.map { m in
            return Promise<(Bookmark?, Int)>(on: .global()) { fulfill, reject in
                m.bookmark_ref.getDocument { snapshot, error in
                    if let error = error {
                        Logger.print(error)
                        reject(error)
                        return
                    }

                    guard let snapshot = snapshot, let dict = snapshot.data() else {
                        Logger.print("snapshotが取れず...")
                        fulfill((nil, 0))
                        return
                    }

                    guard let b = Bookmark(dictionary: dict) else {
                        Logger.print("bookmark decode できず")
                        fulfill((nil, 0))
                        return
                    }

                    if filterOut(bookmarks: [b]).isEmpty {
                        fulfill((nil, 0))
                        return
                    }

                    fulfill((b, m.created_at))
                }
            }
        }

        Promises.all(tasks)
            .then { results in
                let sortedBookmarks = results
                    .filter { $0.0 != nil }
                    .sorted(by: { $0.1 > $1.1 })
                    .compactMap { $0.0 }
                completion(sortedBookmarks)
            }
            .catch { error in
                Logger.print(error)
                completion([])
            }
    }
}
