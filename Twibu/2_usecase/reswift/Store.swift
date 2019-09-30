//
//  ReSwiftImpl.swift
//  Twibu
//
//  Created by abeyuya on 2019/06/23.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import Foundation
import ReSwift
import FirebaseAuth
import Embedded

struct AppState: StateType {
    struct ResponseData {
        var bookmarks: [Embedded.Category: Repository.Result<[Bookmark]>] = [:]
        var comments: [String: Repository.Result<[Comment]>] = [:]
    }

    struct ResponseState {
        var bookmarks: [Embedded.Category: Repository.ResponseState] = [:]
        var comments: [String: Repository.ResponseState] = [:]
    }

    struct HistoryInfo {
        var histories: [(bookmark: Bookmark, createdAt: Int)]
        var hasMore: Bool
    }

    struct WebArchiveInfo {
        var tasks: [WebArchiver] = []
        var results: [(bookmarkUid: String, result: WebArchiver.SaveResult)] = []
    }

    var responseData = ResponseData()
    var responseState = ResponseState()
    var currentUser = TwibuUser(firebaseAuthUser: nil)
    var history = HistoryInfo(histories: [], hasMore: true)
    var webArchive = WebArchiveInfo(tasks: [], results: [])
    var twitterTimelineMaxId: String?
    var lastRefreshAt: [Embedded.Category: Date] = [:]
}

extension AppState {
    static func toFlat(bookmarks: [Embedded.Category: Repository.Result<[Bookmark]>]) -> [Bookmark] {
        let resArr = bookmarks.values.compactMap { $0.item }
        let bmArr: [Bookmark] = resArr.reduce([], +)
        return bmArr
    }
}

struct UpdateBookmarkStateAction: Action {
    let category: Embedded.Category
    let state: Repository.ResponseState
}
struct UpdateCommentStateAction: Action {
    let bookmarkUid: String
    let state: Repository.ResponseState
}
struct AddHistoriesAction: Action {
    let histories: [(Bookmark, Int)]
}
struct AddNewHistoryAction: Action {
    let bookmark: Bookmark
    let createdAt: Int
}
struct DeleteHistoryAction: Action {
    let bookmarkUid: String
}
struct AddBookmarksAction: Action {
    let category: Embedded.Category
    let bookmarks: Repository.Result<[Bookmark]>
}
struct RemoveBookmarkAction: Action {
    let category: Embedded.Category
    let bookmarkUid: String
}
struct ClearBookmarkAction: Action {
    let category: Embedded.Category
}
struct AddCommentsAction: Action {
    let bookmarkUid: String
    let comments: Repository.Result<[Comment]>
}
struct UpdateBookmarkCommentCountIfOverAction: Action {
    let bookmarkUid: String
    let commentCount: Int
}
struct UpdateFirebaseUserAction: Action {
    let newUser: User
}
struct AddWebArchiveTask: Action {
    let webArchiver: WebArchiver
}
struct UpdateWebArchiveResult: Action {
    let bookmarkUid: String
    let result: WebArchiver.SaveResult
}
struct SetMaxIdAction: Action {
    let maxId: String
}
struct SetLastRefreshAtAction: Action {
    let category: Embedded.Category
    let refreshAt: Date
}

func appReducer(action: Action, state: AppState?) -> AppState {
    var state = state ?? AppState()

    switch action {
    case let a as UpdateBookmarkStateAction:
        state.responseState.bookmarks[a.category] = a.state

    case let a as UpdateCommentStateAction:
        state.responseState.comments[a.bookmarkUid] = a.state

    case let a as AddBookmarksAction:
        let old = state.responseData.bookmarks[a.category]?.item ?? []
        let add = a.bookmarks.item
        let newBookmarks: [Bookmark] = {
            switch a.category {
            case .memo, .timeline:
                // 記事作成日とは別の数字で既にソート済み
                return Bookmark.merge(base: old, add: add)
            default:
                return Bookmark
                    .merge(base: old, add: add)
                    .sorted { $0.created_at ?? 0 > $1.created_at ?? 0 }
            }
        }()
        state.responseData.bookmarks[a.category] = Repository.Result<[Bookmark]>(
            item: newBookmarks,
            pagingInfo: a.bookmarks.pagingInfo,
            hasMore: a.bookmarks.hasMore
        )

    case let a as RemoveBookmarkAction:
        state.responseData.bookmarks[a.category] = {
            guard let old = state.responseData.bookmarks[a.category] else {
                return nil
            }

            let newBookmarks = old.item.filter { $0.uid != a.bookmarkUid }
            let newResult = Repository.Result(
                item: newBookmarks,
                pagingInfo: old.pagingInfo,
                hasMore: old.hasMore
            )
            return newResult
        }()

    case let a as ClearBookmarkAction:
        state.responseData.bookmarks[a.category] = Repository.Result<[Bookmark]>(
            item: [],
            pagingInfo: nil,
            hasMore: true
        )

    case let a as AddCommentsAction:
        let old = state.responseData.comments[a.bookmarkUid]?.item ?? []
        let add = a.comments.item
        let newComments = Comment
            .merge(base: old, add: add)
            .sorted { $0.favorite_count > $1.favorite_count }
        state.responseData.comments[a.bookmarkUid] = Repository.Result<[Comment]>(
            item: newComments,
            pagingInfo: a.comments.pagingInfo,
            hasMore: a.comments.hasMore
        )

    case let a as UpdateBookmarkCommentCountIfOverAction:
        var new = state.responseData.bookmarks
        for (category, res) in new {
            var bms = res.item
            guard let index = bms.firstIndex(where: { $0.uid == a.bookmarkUid }) else { continue }
            let oldBookmark = bms[index]

            // 新しいコメント数の方が少ないなら更新しない
            guard oldBookmark.comment_count ?? 0 < a.commentCount else { continue }

            let newBookmark = Bookmark(oldBookmark, commentCount: a.commentCount)
            bms[index] = newBookmark

            let newResult = Repository.Result<[Bookmark]>(
                item: bms,
                pagingInfo: res.pagingInfo,
                hasMore: res.hasMore
            )
            new[category] = newResult
            break
        }
        state.responseData.bookmarks = new

    case let a as UpdateFirebaseUserAction:
        let newUser = TwibuUser(firebaseAuthUser: a.newUser)
        state.currentUser = newUser

    case let a as AddHistoriesAction:
        state.history.histories = (state.history.histories + a.histories)
            .unique(by: { $0.0.uid })
            .sorted { $0.1 > $1.1 }
        state.history.hasMore = !a.histories.isEmpty

    case let a as AddNewHistoryAction:
        state.history.histories.insert((a.bookmark, a.createdAt), at: 0)
        state.history.histories = state.history.histories
            .unique(by: { $0.0.uid })
            .sorted { $0.1 > $1.1 }

    case let a as DeleteHistoryAction:
        if let index = state.history.histories.firstIndex(where: { $0.bookmark.uid == a.bookmarkUid }) {
            state.history.histories.remove(at: index)
        }

    case let a as AddWebArchiveTask:
        state.webArchive.tasks.append(a.webArchiver)

    case let a as UpdateWebArchiveResult:
        if let i = state.webArchive.results.firstIndex(where: { $0.0 == a.bookmarkUid}) {
            state.webArchive.results[i] = (a.bookmarkUid, a.result)
        } else {
            state.webArchive.results.append((a.bookmarkUid, a.result))
        }

    case let a as SetMaxIdAction:
        state.twitterTimelineMaxId = a.maxId

    case let a as SetLastRefreshAtAction:
        state.lastRefreshAt[a.category] = a.refreshAt

    default:
        break
    }

    return state
}

let store = Store(
    reducer: appReducer,
    state: AppState(),
    middleware: []
)

extension Store {
    func mDispatch(_ action: Action) {
        DispatchQueue.main.async {
            self.dispatch(action)
        }
    }
}
