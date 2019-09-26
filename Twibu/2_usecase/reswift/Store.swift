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
    struct Response {
        var bookmarks: [Embedded.Category: Repository.Response<[Bookmark]>] = [:]
        var comments: [String: Repository.Response<[Comment]>] = [:]
    }

    struct HistoryInfo {
        var histories: [(bookmark: Bookmark, createdAt: Int)]
        var hasMore: Bool
    }

    struct WebArchiveInfo {
        var tasks: [WebArchiver] = []
        var results: [(bookmarkUid: String, result: WebArchiver.SaveResult)] = []
    }

    var response: Response = Response()
    var currentUser = TwibuUser(firebaseAuthUser: nil)
    var history = HistoryInfo(histories: [], hasMore: true)
    var webArchive = WebArchiveInfo(tasks: [], results: [])
}

extension AppState {
    static func toFlat(bookmarks: [Embedded.Category: Repository.Response<[Bookmark]>]) -> [Bookmark] {
        let resArr = bookmarks.values.compactMap { $0 }
        let bmNestArr: [[Bookmark]] = resArr.compactMap { (res: Repository.Response<[Bookmark]>) in
            switch res {
            case .success(let result): return result.item
            case .loading(let result): return result.item
            case .failure: return nil
            case .notYetLoading: return nil
            }
        }
        let bmArr: [Bookmark] = bmNestArr.reduce([], +)
        return bmArr
    }
}

struct AddHistoriesAction: Action {
    let histories: [(Bookmark, Int)]
}
struct AddNewHistoryAction: Action {
    let bookmark: Bookmark
    let createdAt: Int
}
struct AddBookmarksAction: Action {
    let category: Embedded.Category
    let bookmarks: Repository.Response<[Bookmark]>
}
struct RemoveBookmarkAction: Action {
    let category: Embedded.Category
    let bookmarkUid: String
}
struct AddCommentsAction: Action {
    let bookmarkUid: String
    let comments: Repository.Response<[Comment]>
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

func appReducer(action: Action, state: AppState?) -> AppState {
    var state = state ?? AppState()

    switch action {
    case let a as AddBookmarksAction:
        let old: [Bookmark] = {
            let s = state.response.bookmarks[a.category] ?? .notYetLoading
            switch s {
            case .success(let res):
                return res.item
            case .loading(let res):
                return res.item
            default:
                return []
            }
        }()

        let add: [Bookmark] = {
            switch a.bookmarks {
            case .success(let res):
                return res.item
            case .loading(let res):
                return res.item
            default:
                return []
            }
        }()

        let new: [Bookmark] = {
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

        state.response.bookmarks[a.category] = {
            switch a.bookmarks {
            case .success(let old):
                let result = Repository.Result(
                    item: new,
                    pagingInfo: old.pagingInfo,
                    hasMore: old.hasMore
                )
                return .success(result)
            case .loading(let old):
                let result = Repository.Result(
                    item: new,
                    pagingInfo: old.pagingInfo,
                    hasMore: old.hasMore
                )
                return .loading(result)
            case .failure: return a.bookmarks
            case .notYetLoading: return .notYetLoading
            }
        }()

    case let a as RemoveBookmarkAction:
        state.response.bookmarks[a.category] = {
            guard let res = state.response.bookmarks[a.category] else {
                return nil
            }

            switch res {
            case .failure(_), .notYetLoading:
                return res
            case .success(let result):
                let newBookmarks = result.item.filter { $0.uid != a.bookmarkUid }
                let newResult = Repository.Result(
                    item: newBookmarks,
                    pagingInfo: result.pagingInfo,
                    hasMore: result.hasMore
                )
                return Repository.Response.success(newResult)
            case .loading(let result):
                let newBookmarks = result.item.filter { $0.uid != a.bookmarkUid }
                let newResult = Repository.Result(
                    item: newBookmarks,
                    pagingInfo: result.pagingInfo,
                    hasMore: result.hasMore
                )
                return Repository.Response.loading(newResult)
            }
        }()

    case let a as AddCommentsAction:
        let old: [Comment] = {
            let s = state.response.comments[a.bookmarkUid] ?? .notYetLoading
            switch s {
            case .success(let res):
                return res.item
            case .loading(let res):
                return res.item
            default:
                return []
            }
        }()

        let add: [Comment] = {
            switch a.comments {
            case .success(let res):
                return res.item
            case .loading(let res):
                return res.item
            default:
                return []
            }
        }()

        let new = Comment
            .merge(base: old, add: add)
            .sorted { $0.favorite_count > $1.favorite_count }

        state.response.comments[a.bookmarkUid] = {
            switch a.comments {
            case .success(let old):
                let result = Repository.Result<[Comment]>(
                    item: new,
                    pagingInfo: old.pagingInfo,
                    hasMore: old.hasMore
                )
                return .success(result)
            case .loading(let old):
                let result = Repository.Result<[Comment]>(
                    item: new,
                    pagingInfo: old.pagingInfo,
                    hasMore: old.hasMore
                )
                return .loading(result)
            case .failure(_): return a.comments
            case .notYetLoading: return .notYetLoading
            }
        }()

    case let a as UpdateBookmarkCommentCountIfOverAction:
        var new = state.response.bookmarks
        for (category, res) in new {
            // そもそも読み込み完了していない場合は更新しない
            switch res {
            case .success(_):
                break
            default:
                continue
            }

            guard var bms = res.item else { continue }
            guard let index = bms.firstIndex(where: { $0.uid == a.bookmarkUid }) else { continue }
            let oldBookmark = bms[index]

            // 新しいコメント数の方が少ないなら更新しない
            guard oldBookmark.comment_count ?? 0 < a.commentCount else { continue }

            let newBookmark = Bookmark(oldBookmark, commentCount: a.commentCount)
            bms[index] = newBookmark

            switch res {
            case .notYetLoading, .failure(_):
                continue
            case .loading(_):
                //
                // NOTE:
                //   timelineのpagingでまだ読み込み完了していない状態 & 読み込み済み記事のコメント表示
                //   の時に通ったよ
                //
                continue
            case .success(let result):
                let newResult = Repository.Result<[Bookmark]>(
                    item: bms,
                    pagingInfo: result.pagingInfo,
                    hasMore: result.hasMore
                )
                new[category] = .success(newResult)
            }
            break
        }
        state.response.bookmarks = new

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

    case let a as AddWebArchiveTask:
        state.webArchive.tasks.append(a.webArchiver)

    case let a as UpdateWebArchiveResult:
        if let i = state.webArchive.results.firstIndex(where: { $0.0 == a.bookmarkUid}) {
            state.webArchive.results[i] = (a.bookmarkUid, a.result)
        } else {
            state.webArchive.results.append((a.bookmarkUid, a.result))
        }

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
