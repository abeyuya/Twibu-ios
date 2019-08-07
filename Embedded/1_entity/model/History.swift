//
//  History.swift
//  Embedded
//
//  Created by abeyuya on 2019/08/07.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import RealmSwift

final public class History: Object {
    @objc public dynamic var bookmarkUid = ""
    @objc public dynamic var bookmarkData: Data?
    @objc public var createdAt: Int = 0

    public func decodedBookmark() -> Bookmark? {
        guard let d = bookmarkData else { return nil }
        return try? JSONDecoder().decode(Bookmark.self, from: d)
    }

    override public static func primaryKey() -> String? {
        return "bookmarkUid"
    }

    override public static func indexedProperties() -> [String] {
        return ["createdAt"]
    }
}
