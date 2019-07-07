//
//  Bookmark.swift
//  Twibu
//
//  Created by abeyuya on 2019/06/17.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import Foundation
import FirebaseFirestore

struct Bookmark: TwibuFirestoreCodable {
    let uid: String
    let title: String?
    let image_url: String?
    let description: String?
    let comment_count: Int?
    let created_at: Int?
    let updated_at: Int?
    let url: String
    // let category: Category

    var trimmedTitle: String? {
        return title?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

extension Bookmark {
    init(_ bookmark: Bookmark, commentCount: Int) {
        uid = bookmark.uid
        title = bookmark.title
        image_url = bookmark.image_url
        description = bookmark.description
        comment_count = commentCount // これだけ差し替えている
        created_at = bookmark.created_at
        updated_at = bookmark.updated_at
        url = bookmark.url
    }
}

extension Bookmark {
    // 古いものを新しいもので置き換えつつ合体する
    static func merge(base: [Bookmark], add: [Bookmark]) -> [Bookmark] {
        var result = base

        add.forEach { b in
            if let i = result.firstIndex(where: { $0.uid == b.uid }) {
                result[i] = b
                return
            }
            result.append(b)
        }

        return result
    }
}
