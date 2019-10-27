//
//  HistoryRepository.swift
//  Embedded
//
//  Created by abeyuya on 2019/08/07.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import Embedded
import RealmSwift

public enum HistoryRepository {
    private static let realm: Realm = {
        var config = Realm.Configuration()
        let url = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.github.abeyuya.Twibu"
        )!
        config.fileURL = url.appendingPathComponent("db.realm")
        return try! Realm()
    }()

    public static func addHistory(bookmark: Bookmark) -> History {
        let h = History()
        h.bookmarkUid = bookmark.uid
        h.bookmarkData = try? JSONEncoder().encode(bookmark)
        h.createdAt = Int(Date().timeIntervalSince1970)
        try! realm.write {
            realm.add(h, update: .all)
        }

        return h
    }

    private static let fetchLimit: Int = 30

    public static func fetchHistory(offset: Int, completion: @escaping ([History]) -> Void) {
        let histories: [History] = {
            let result = realm
                .objects(History.self)
                .sorted(byKeyPath: "createdAt", ascending: false)

            if result.count <= offset {
                return []
            }

            var his: [History] = []
            for i in max(0, offset) ..< min(offset + fetchLimit, result.count) {
                his.append(result[i])
            }
            return his
        }()

        completion(histories)
    }

    static func fetchHistory(bookmarkUid: String, completion: @escaping (History?) -> Void) {
        let h = realm.objects(History.self).filter("bookmarkUid == %@", bookmarkUid).first
        completion(h)
    }

    static func isExist(bookmarkUid: String) -> Bool {
        let h = realm.objects(History.self).filter("bookmarkUid == %@", bookmarkUid).first
        if h == nil {
            return false
        }
        return true
    }

    static func deleteHistory(bookmarkUid: String) {
        let h = realm.objects(History.self).filter("bookmarkUid == %@", bookmarkUid)
        try! realm.write {
            realm.delete(h)
        }
    }
}
