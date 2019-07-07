//
//  BookmarkRepository.swift
//  Twibu
//
//  Created by abeyuya on 2019/06/21.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import FirebaseAuth
import FirebaseFirestore

final class BookmarkRepository {
    private static let db = TwibuFirebase.firestore

    static func fetchBookmark(category: Category, uid: String, completion: @escaping (Repository.Response<[Bookmark]>) -> Void) {
        if category == .timeline {
            fetchTimelineBookmarks(uid: uid, completion: completion)
            return
        }

        buildQuery(category: category).getDocuments() { snapshot, error in
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

                if category == .all {
                    return b.filter { $0.comment_count ?? 0 > 20 }
                }

                return b
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

    static private func buildQuery(category: Category) -> Query {
        switch category {
        case .all:
            return db.collection("bookmarks")
                .order(by: "created_at", descending: true)
                .limit(to: 100)
        default:
            return db.collection("bookmarks")
                .whereField("category", isEqualTo: category.rawValue)
                .order(by: "created_at", descending: true)
                .limit(to: 30)
        }
    }

    private static func fetchTimelineBookmarks(uid: String, completion: @escaping (Repository.Response<[Bookmark]>) -> Void) {
        let query = db.collection("users")
            .document(uid)
            .collection("timeline")
            .order(by: "created_at", descending: true)
            .limit(to: 20)

        query.getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(.firestoreError(error.localizedDescription)))
                return
            }

            guard let snapshot = snapshot else {
                completion(.failure(.firestoreError("no result")))
                return
            }

            let timelines = snapshot.documents.compactMap { $0.data() }
            print(timelines)

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

    private static func execConcurrentFetch(timelines: [[String: Any]], completion: @escaping ([Bookmark]) -> Void) {
        let dispatchGroup = DispatchGroup()
        let dispatchQueue = DispatchQueue(label: "queue", attributes: .concurrent)
        var results: [Bookmark] = []

        timelines.forEach { t in
            guard let ref = t["bookmark_ref"] as? DocumentReference else {
                return
            }

            dispatchGroup.enter()
            dispatchQueue.async(group: dispatchGroup) {
                ref.getDocument { snapshot, error in
                    if let error = error {
                        print(error)
                        dispatchGroup.leave()
                        return
                    }

                    guard let snapshot = snapshot, let dict = snapshot.data() else {
                        print("snapshotが取れず...")
                        dispatchGroup.leave()
                        return
                    }

                    guard let b = Bookmark(dictionary: dict) else {
                        print("bookmark decode できず")
                        dispatchGroup.leave()
                        return
                    }

                    results.append(b)
                    dispatchGroup.leave()
                }
            }
        }

        dispatchGroup.notify(queue: .global()) {
            completion(results)
        }
    }
}
