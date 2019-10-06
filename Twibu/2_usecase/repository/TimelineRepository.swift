//
//  TimelineRepository.swift
//  Twibu
//
//  Created by abeyuya on 2019/10/03.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import Embedded
import FirebaseFirestore
import Promises

enum TimelineRepository {
    static let db = TwibuFirebase.shared.firestore

    static func fetchTimeline(
        userUid: String,
        type: Repository.FetchType,
        completion: @escaping (Result<Repository.Result<[TimelineReducer.Info]>>) -> Void
    ) {
        let query: Query = {
            switch type {
            case .new(let limit):
                return db.collection("users")
                    .document(userUid)
                    .collection("timeline")
                    .order(by: "post_at", descending: true)
                    .limit(to: limit)
            case .add(let (limit, info)):
                guard let d = info?.lastSnapshot as? DocumentSnapshot else {
                    return db.collection("users")
                        .document(userUid)
                        .collection("timeline")
                        .order(by: "post_at", descending: true)
                        .limit(to: limit)
                }
                return db.collection("users")
                    .document(userUid)
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

    private static func execConcurrentFetch(
        timelines: [Timeline],
        completion: @escaping ([TimelineReducer.Info]) -> Void
    ) {
        let tasks = timelines.map { t in
            return Promise<TimelineReducer.Info?>(on: .global()) { fulfill, reject in
                t.bookmark_ref.getDocument { snapshot, error in
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

                    fulfill(TimelineReducer.Info(timeline: t, bookmark: b))
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
}
