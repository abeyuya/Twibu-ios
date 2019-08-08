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
            let bookmarks = histories.compactMap { $0.decodedBookmark() }
            let a = AddHistoriesAction(bookmarks: bookmarks)
            store.mDispatch(a)
        }
    }

    static func addNewHistory(bookmark: Bookmark) {
        let a = AddNewHistoryAction(bookmark: bookmark)
        store.mDispatch(a)
    }
}
