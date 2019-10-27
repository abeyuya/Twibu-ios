//
//  HistoryArticleListViewModel.swift
//  Twibu
//
//  Created by abeyuya on 2019/08/08.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import Embedded
import ReSwift

final class HistoryArticleListViewModel: ArticleList {
    internal weak var delegate: ArticleListDelegate?

    var type: ArticleListType {
        return .history
    }
    var currentUser: TwibuUser?
    var bookmarks: [Bookmark] = []
    var hasMore = true
    var webArchiveResults: [(String, WebArchiver.SaveResult)] = []

    init(delegate: ArticleListDelegate, type: ArticleListType) {
        self.delegate = delegate
    }
}

// input
extension HistoryArticleListViewModel {
    func startSubscribe() {
        store.subscribe(self) { subcription in
            subcription.select { state in
                return Props(
                    historyInfo: state.history,
                    currentUser: state.currentUser
                )
            }
        }
    }

    func stopSubscribe() {
        store.unsubscribe(self)
    }

    func fetchBookmark() {
        HistoryDispatcher.fetchHistory(offset: 0)
    }

    func fetchAdditionalBookmarks() {
        if hasMore {
            HistoryDispatcher.fetchHistory(offset: bookmarks.count)
        }
    }

    func deleteBookmark(bookmarkUid: String, completion: (Result<Void, TwibuError>) -> Void) {
        HistoryDispatcher.deleteHistory(bookmarkUid: bookmarkUid)
        completion(.success(Void()))
    }
}

extension HistoryArticleListViewModel: StoreSubscriber {
    struct Props {
        var historyInfo: HistoryReducer.State
        var currentUser: TwibuUser
    }

    typealias StoreSubscriberStateType = Props

    func newState(state: Props) {
        currentUser = state.currentUser
        bookmarks = state.historyInfo.histories.map { $0.0 }
        hasMore = state.historyInfo.hasMore
        delegate?.render(state: .success)
    }
}
