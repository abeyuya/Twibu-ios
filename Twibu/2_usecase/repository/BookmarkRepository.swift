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
        completion: @escaping (Result<Repository.Result<[Bookmark]>, TwibuError>) -> Void
    ) {
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
