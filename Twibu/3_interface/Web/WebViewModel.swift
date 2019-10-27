//
//  WebViewModel.swift
//  Twibu
//
//  Created by abeyuya on 2019/10/08.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import ReSwift
import Embedded

protocol WebViewModelDelegate: class {
    func updateNavigation(title: String?, url: String?)
    func renderBadgeCount(count: Int)
}

final class WebViewModel {
    enum ViewMode {
        case online, offline
    }

    var bookmark: Bookmark!
    var currentUser: TwibuUser?
    var isShowComment = false
    var viewMode: ViewMode = .online

    private weak var delegate: WebViewModelDelegate!

    init(bookmark: Bookmark, delegate: WebViewModelDelegate) {
        self.bookmark = bookmark
        self.delegate = delegate
    }
}

extension WebViewModel {
    func startSubscribe() {
        store.subscribe(self) { subcription in
            subcription.select { state in
                let bms = CategoryReducer.allBookmarks(state: state.category)
                let b = bms.first { $0.uid == self.bookmark.uid }
                return Props(
                    bookmark: b,
                    currentUser: state.currentUser
                )
            }
        }
    }

    func stopSubscribe() {
        store.unsubscribe(self)
    }

    func goBackground() {
        HistoryDispatcher.setLocalNotificationIfNeeded(bookmarkUid: bookmark.uid)
    }
}

extension WebViewModel: StoreSubscriber {
    struct Props {
        var bookmark: Bookmark?
        var currentUser: TwibuUser
    }

    typealias StoreSubscriberStateType = Props

    func newState(state: Props) {
        currentUser = state.currentUser
        guard let b = state.bookmark else { return }

        self.bookmark = b
        delegate?.updateNavigation(title: b.title, url: b.url)

        if let c = b.comment_count {
            delegate?.renderBadgeCount(count: c)
        }
    }
}
