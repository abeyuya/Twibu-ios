//
//  HistoryDispatcher.swift
//  Twibu
//
//  Created by abeyuya on 2019/08/09.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import Foundation
import Embedded

enum HistoryDispatcher {
    static func fetchHistory(offset: Int) {
        HistoryRepository.fetchHistory(offset: offset) { histories in
            let h = histories
                .map { (his: History) -> (Bookmark, Int)? in
                    guard let b = his.decodedBookmark() else { return nil }
                    return (b, his.createdAt)
                }
                .compactMap { $0 }

            let a = HistoryReducer.Actions.Add(histories: h)
            store.mDispatch(a)
        }
    }

    static func addNewHistory(bookmark: Bookmark) {
        let h = HistoryRepository.addHistory(bookmark: bookmark)
        let a = HistoryReducer.Actions.Add(histories: [(bookmark, h.createdAt)])
        store.mDispatch(a)
    }

    static func deleteHistory(bookmarkUid: String) {
        HistoryRepository.deleteHistory(bookmarkUid: bookmarkUid)
        let a = HistoryReducer.Actions.Delete(bookmarkUid: bookmarkUid)
        store.mDispatch(a)
    }

    static func setLocalNotificationIfNeeded(bookmarkUid: String) {
        HistoryRepository.fetchHistory(bookmarkUid: bookmarkUid) { h in
            guard let h = h else {
                assertionFailure("通らないはず。履歴がないのにリマインド設定しようとしている")
                return
            }
        }
    }
}
