//
//  CategoryReducer.swift
//  Twibu
//
//  Created by abeyuya on 2019/10/02.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import ReSwift
import Embedded

enum CategoryReducer {
    struct State {
        var result: [Embedded.Category: Repository.Result<[Bookmark]>] = [:]
        var state: [Embedded.Category: Repository.ResponseState] = [:]
        var lastRefreshAt: [Embedded.Category: Date] = [:]
    }

    static func allBookmarks(state: State) -> [Bookmark] {
        let bmArrArr = state.result.values.compactMap { $0.item }
        let bmArr: [Bookmark] = bmArrArr.reduce([], +)
        return bmArr
    }

    enum Actions {
        struct UpdateState: Action {
            let category: Embedded.Category
            let state: Repository.ResponseState
        }
        struct AddBookmarks: Action {
            let category: Embedded.Category
            let result: Repository.Result<[Bookmark]>
        }
        struct RemoveBookmark: Action {
            let category: Embedded.Category
            let bookmarkUid: String
        }
        struct ClearCategory: Action {
            let category: Embedded.Category
        }
        struct UpdateBookmarkCommentCountIfOver: Action {
            let bookmarkUid: String
            let commentCount: Int
        }
        struct SetLastRefreshAt: Action {
            let category: Embedded.Category
            let refreshAt: Date
        }
    }

    static func reducer(action: Action, state: State?) -> State {
        var state = state ?? State()

        switch action {
        case let a as Actions.UpdateState:
            state.state[a.category] = a.state

        case let a as Actions.AddBookmarks:
            let old = state.result[a.category]?.item ?? []
            let add = a.result.item
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
            state.result[a.category] = Repository.Result<[Bookmark]>(
                item: newBookmarks,
                pagingInfo: a.result.pagingInfo,
                hasMore: a.result.hasMore
            )

        case let a as Actions.RemoveBookmark:
            state.result[a.category] = {
                guard let old = state.result[a.category] else { return nil }
                let newBookmarks = old.item.filter { $0.uid != a.bookmarkUid }
                return Repository.Result(
                    item: newBookmarks,
                    pagingInfo: old.pagingInfo,
                    hasMore: old.hasMore
                )
            }()

        case let a as Actions.ClearCategory:
            state.result[a.category] = Repository.Result<[Bookmark]>(
                item: [],
                pagingInfo: nil,
                hasMore: true
            )

        case let a as Actions.UpdateBookmarkCommentCountIfOver:
            var newResult = state.result
            for (category, r) in newResult {
                var bms = r.item
                guard let index = bms.firstIndex(where: { $0.uid == a.bookmarkUid }) else { continue }
                let oldBookmark = bms[index]

                // 新しいコメント数の方が少ないなら更新しない
                guard oldBookmark.comment_count ?? 0 < a.commentCount else { continue }

                let newBookmark = Bookmark(oldBookmark, commentCount: a.commentCount)
                bms[index] = newBookmark

                let newR = Repository.Result<[Bookmark]>(
                    item: bms,
                    pagingInfo: r.pagingInfo,
                    hasMore: r.hasMore
                )
                newResult[category] = newR
                break
            }
            state.result = newResult

        case let a as Actions.SetLastRefreshAt:
            state.lastRefreshAt[a.category] = a.refreshAt

        default:
            break
        }

        return state
    }
}
