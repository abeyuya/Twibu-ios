//
//  Bookmark.swift
//  Twibu
//
//  Created by abeyuya on 2019/06/17.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import Foundation

public struct Bookmark: Codable, Equatable {
    public let uid: String
    public let title: String?
    public let image_url: String?
    public let description: String?
    public let comment_count: Int?
    public let created_at: Int?
    public let updated_at: Int?
    public let url: String
    public let category: Category

    public var trimmedTitle: String? {
        return title?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public var twitterSearchUrl: URL? {
        let str = "https://twitter.com/search?src=typd&q=\(url)"
        return URL(string: str)
    }

    public init(
        uid: String,
        title: String?,
        image_url: String?,
        description: String?,
        comment_count: Int?,
        created_at: Int?,
        updated_at: Int?,
        url: String,
        category: Category?
    ) {
        self.uid = uid
        self.title = title
        self.image_url = image_url
        self.description = description
        self.comment_count = comment_count
        self.created_at = created_at
        self.updated_at = updated_at
        self.url = url
        self.category = category ?? .unknown
    }
}

public extension Bookmark {
    init(_ bookmark: Bookmark, commentCount: Int) {
        uid = bookmark.uid
        title = bookmark.title
        image_url = bookmark.image_url
        description = bookmark.description
        comment_count = commentCount // これだけ差し替えている
        created_at = bookmark.created_at
        updated_at = bookmark.updated_at
        url = bookmark.url
        category = bookmark.category
    }
}

public extension Bookmark {
    static func buildFirestoreDebugLink(buid: String) -> URL {
        let str = "https://console.firebase.google.com/project/twibu-c4d5a/database/firestore/data~2Fbookmarks~2F\(buid)"

        return URL(string: str)!
    }
}

