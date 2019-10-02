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
    struct Info {
        var result: Repository.Result<[Bookmark]>
        var state: Repository.ResponseState
    }

    typealias State = [Embedded.Category: Info]

    static func allBookmarks(state: State) -> [Bookmark] {
        let bmArrArr = state.values.compactMap { $0.result.item }
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
    }

    static func reducer(action: Action, state: State?) -> State {
        var state = state ?? State()

        switch action {
        case let a as Actions.UpdateState:
            state[a.category] = {
                if let i = state[a.category] {
                    return Info(result: i.result, state: a.state)
                }
                return Info(
                    result: Repository.Result<[Bookmark]>(
                        item: [],
                        pagingInfo: nil,
                        hasMore: true
                    ),
                    state: a.state
                )
            }()

        case let a as Actions.AddBookmarks:
            let old = state[a.category]?.result.item ?? []
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
            state[a.category] = {
                if let i = state[a.category] {
                    return Info(
                        result: Repository.Result<[Bookmark]>(
                            item: newBookmarks,
                            pagingInfo: a.result.pagingInfo,
                            hasMore: a.result.hasMore
                        ),
                        state: i.state
                    )
                }
                return Info(
                    result: Repository.Result<[Bookmark]>(
                        item: newBookmarks,
                        pagingInfo: nil,
                        hasMore: true
                    ),
                    state: .notYetLoading
                )
            }()

        case let a as Actions.RemoveBookmark:
            state[a.category] = {
                guard let old = state[a.category] else { return nil }
                let newBookmarks = old.result.item.filter { $0.uid != a.bookmarkUid }
                let newResult = Repository.Result(
                    item: newBookmarks,
                    pagingInfo: old.result.pagingInfo,
                    hasMore: old.result.hasMore
                )
                return Info(result: newResult, state: old.state)
            }()

        case let a as Actions.ClearCategory:
            state[a.category] = {
                guard let old = state[a.category] else { return nil }
                return Info(
                    result: Repository.Result<[Bookmark]>(
                        item: [],
                        pagingInfo: nil,
                        hasMore: true
                    ),
                    state: old.state
                )
            }()

        case let a as Actions.UpdateBookmarkCommentCountIfOver:
            var newState = state
            for (category, info) in newState {
                var bms = info.result.item
                guard let index = bms.firstIndex(where: { $0.uid == a.bookmarkUid }) else { continue }
                let oldBookmark = bms[index]

                // 新しいコメント数の方が少ないなら更新しない
                guard oldBookmark.comment_count ?? 0 < a.commentCount else { continue }

                let newBookmark = Bookmark(oldBookmark, commentCount: a.commentCount)
                bms[index] = newBookmark

                let newResult = Repository.Result<[Bookmark]>(
                    item: bms,
                    pagingInfo: info.result.pagingInfo,
                    hasMore: info.result.hasMore
                )
                newState[category] = Info(result: newResult, state: info.state)
                break
            }
            state = newState

        default:
            break
        }

        return state
    }
}
