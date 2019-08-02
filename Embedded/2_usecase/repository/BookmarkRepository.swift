//
//  BookmarkRepository.swift
//  Twibu
//
//  Created by abeyuya on 2019/06/21.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import Foundation
import FirebaseFirestore

public final class BookmarkRepository {
    public static func fetchBookmark(
        db: Firestore,
        category: Category,
        uid: String,
        type: Repository.FetchType,
        commentCountOffset: Int,
        completion: @escaping (Repository.Response<[Bookmark]>) -> Void
    ) {
        if category == .timeline {
            fetchTimelineBookmarks(db: db, uid: uid, type: type, completion: completion)
            return
        }

        buildQuery(db: db, category: category, type: type).getDocuments() { snapshot, error in
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
                let filtered = b.filter { $0.comment_count ?? 0 >= commentCountOffset }
                return filterOut(bookmarks: filtered)
            }()

            let result: Repository.Result<[Bookmark]> = {
                guard let last = snapshot.documents.last else {
                    return Repository.Result(
                        item: item,
                        lastSnapshot: nil,
                        hasMore: false
                    )
                }

                return Repository.Result(
                    item: item,
                    lastSnapshot: last,
                    hasMore: !snapshot.documents.isEmpty
                )
            }()

            completion(.success(result))
        }
    }

    static private func buildQuery(db: Firestore, category: Category, type: Repository.FetchType) -> Query {
        switch category {
        case .all:
            switch type {
            case .new(let limit):
                return db.collection("bookmarks")
                    .order(by: "created_at", descending: true)
                    .limit(to: limit)
            case .add(let (limit, doc)):
                if let d = doc {
                    return db.collection("bookmarks")
                        .order(by: "created_at", descending: true)
                        .start(afterDocument: d)
                        .limit(to: limit)
                }
                return db.collection("bookmarks")
                    .order(by: "created_at", descending: true)
                    .limit(to: limit)
            }
        default:
            switch type {
            case .new(let limit):
                return db.collection("bookmarks")
                    .whereField("category", isEqualTo: category.rawValue)
                    .order(by: "created_at", descending: true)
                    .limit(to: limit)
            case .add(let (limit, doc)):
                if let d = doc {
                    return db.collection("bookmarks")
                        .whereField("category", isEqualTo: category.rawValue)
                        .order(by: "created_at", descending: true)
                        .start(afterDocument: d)
                        .limit(to: limit)
                }
                return db.collection("bookmarks")
                    .whereField("category", isEqualTo: category.rawValue)
                    .order(by: "created_at", descending: true)
                    .limit(to: limit)
            }
        }
    }

    private static func fetchTimelineBookmarks(
        db: Firestore,
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
            case .add(let (limit, doc)):
                if let d = doc {
                    return db.collection("users")
                        .document(uid)
                        .collection("timeline")
                        .order(by: "post_at", descending: true)
                        .start(afterDocument: d)
                        .limit(to: limit)
                }
                return db.collection("users")
                    .document(uid)
                    .collection("timeline")
                    .order(by: "post_at", descending: true)
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
                let result: Repository.Result<[Bookmark]> = {
                    guard let last = snapshot.documents.last else {
                        return Repository.Result(
                            item: bookmarks,
                            lastSnapshot: nil,
                            hasMore: false
                        )
                    }

                    return Repository.Result(
                        item: bookmarks,
                        lastSnapshot: last,
                        hasMore: !snapshot.documents.isEmpty
                    )
                }()

                completion(.success(result))
            }
        }
    }

    private static func execConcurrentFetch(timelines: [Timeline], completion: @escaping ([Bookmark]) -> Void) {
        let dispatchGroup = DispatchGroup()
        let dispatchQueue = DispatchQueue(label: "queue", attributes: .concurrent)
        let serialQueue = DispatchQueue(label: "serialQueue")

        var results: [(Bookmark, Int)] = []

        timelines.forEach { t in
            dispatchGroup.enter()
            dispatchQueue.async(group: dispatchGroup) {
                t.bookmark_ref.getDocument { snapshot, error in
                    if let error = error {
                        Logger.print(error)
                        dispatchGroup.leave()
                        return
                    }

                    guard let snapshot = snapshot, let dict = snapshot.data() else {
                        Logger.print("snapshotが取れず...")
                        dispatchGroup.leave()
                        return
                    }

                    guard let b = Bookmark(dictionary: dict) else {
                        Logger.print("bookmark decode できず")
                        dispatchGroup.leave()
                        return
                    }

                    if filterOut(bookmarks: [b]).isEmpty {
                        dispatchGroup.leave()
                        return
                    }

                    DispatchQueue.global().async {
                        dispatchGroup.leave()
                    }
                    // https://stackoverflow.com/questions/40080508/swift-unsafemutablepointer-deinitialize-fatal-error-with-negative-count-when-ap
                    serialQueue.sync {
                        results.append((b, t.post_at))
                    }
                }
            }

            dispatchGroup.notify(queue: .global()) {
                let sortedBookmarks = results
                    .sorted(by: { $0.1 > $1.1 })
                    .map { $0.0 }
                completion(sortedBookmarks)
            }
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
}
