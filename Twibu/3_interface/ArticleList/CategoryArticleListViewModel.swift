//
//  ArticleListViewModel.swift
//  Twibu
//
//  Created by abeyuya on 2019/08/08.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import Embedded
import ReSwift

final class CategoryArticleListViewModel: ArticleList {
    internal weak var delegate: ArticleListDelegate?
    private var responseData: Repository.Result<[Bookmark]>?
    private var responseState: Repository.ResponseState = .notYetLoading
    private var category: Embedded.Category {
        switch type {
        case .category(let c):
            return c
        case .history, .memo:
            assertionFailure("来ないはず")
            return .all
        }
    }

    var type: ArticleListType = .category(.all)
    var currentUser: TwibuUser?
    var bookmarks: [Bookmark] {
        return responseData?.item ?? []
    }
    var webArchiveResults: [(String, WebArchiver.SaveResult)] = []
    var twitterMaxId: String?
    var lastRefreshCheckAt: Date?
}

// input
extension CategoryArticleListViewModel {
    func set(delegate: ArticleListDelegate, type: ArticleListType) {
        self.delegate = delegate
        self.type = type
    }

    func startSubscribe() {
        store.subscribe(self) { [weak self] subcription in
            subcription.select { state in
                return Props(
                    responseData: {
                        guard let c = self?.category else { return nil }
                        return state.category.result[c]
                    }(),
                    responseState: {
                        guard let c = self?.category else { return .notYetLoading }
                        return state.category.state[c] ?? .notYetLoading
                    }(),
                    currentUser: state.currentUser,
                    webArchiveResults: state.webArchive.results,
                    twitterMaxId: state.timeline.twitterTimelineMaxId,
                    lastRefreshCheckAt: {
                        guard let c = self?.category else { return nil }
                        return state.category.lastRefreshAt[c]
                    }()
                )
            }
        }

        refreshCheck()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refreshCheck),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    func stopSubscribe() {
        store.unsubscribe(self)
    }

    func fetchBookmark() {
        guard let uid = currentUser?.firebaseAuthUser?.uid else { return }

        if category == .timeline, currentUser?.isTwitterLogin == true {
            refreshForLoginUser()
            return
        }

        let limit: Int = {
            switch category {
            case .all: return 100
            default: return 30
            }
        }()

        BookmarkDispatcher.fetchBookmark(
            category: category,
            uid: uid,
            type: .new(limit: limit),
            commentCountOffset: category == .all ? 20 : 0
        ) { _ in }
    }

    func fetchAdditionalBookmarks() {
        switch responseState {
        case .loading, .additionalLoading:
            return
        case .notYetLoading:
            // view読み込み時だけ通る
            return
        case .failure:
            return
        case .success:
            switch type {
            case .history, .memo:
                assertionFailure("通らないはず")
                break
            case .category(let c):
                let d: Repository.Result<[Bookmark]> = {
                    if let d = responseData {
                        return d
                    }
                    return .init(item: [], pagingInfo: nil, hasMore: true)
                }()
                switch c {
                case .timeline:
                    fetchAdditionalForTimeline(result: d)
                default:
                    fetchAdditionalForAllCategory(result: d)
                }
            }
        }
    }

    private func fetchAdditionalForTimeline(result: Repository.Result<[Bookmark]>) {
        guard let uid = currentUser?.firebaseAuthUser?.uid else { return }
        if result.hasMore {
            BookmarkDispatcher.fetchBookmark(
                category: .timeline,
                uid: uid,
                type: .add(limit: 30, pagingInfo: result.pagingInfo),
                commentCountOffset: 0
            ) { _ in }
            return
        }

        // NOTE: onCreateBookmark完了まで待ちたいので、loadingを発行しておく
        BookmarkDispatcher.updateState(c: category, s: .additionalLoading)

        UserDispatcher.kickTwitterTimelineScrape(uid: uid, maxId: twitterMaxId) { [weak self] kickResult in
            guard let self = self else { return }
            switch kickResult {
            case .failure(let e):
                BookmarkDispatcher.updateState(c: self.category, s: .failure(e))
                self.delegate?.render(state: .failure(error: e))
            case .success(_):
                BookmarkDispatcher.updateState(c: self.category, s: .success)
                DispatchQueue.main.async {
                    let r = Repository.Result<[Bookmark]>(
                        item: result.item,
                        pagingInfo: result.pagingInfo,
                        hasMore: true // これを渡したい
                    )
                    self.fetchAdditionalForTimeline(result: r)
                }
            }
        }
    }

    private func fetchAdditionalForAllCategory(result: Repository.Result<[Bookmark]>) {
        guard let uid = currentUser?.firebaseAuthUser?.uid, result.hasMore else { return }
        BookmarkDispatcher.fetchBookmark(
            category: category,
            uid: uid,
            type: .add(limit: 30, pagingInfo: result.pagingInfo),
            commentCountOffset: category == .all ? 20 : 0
        ) { _ in }
    }

    func deleteBookmark(bookmarkUid: String, completion: @escaping (Result<Void>) -> Void) {
        assertionFailure("来ないはず")
    }

    private func refreshForLoginUser() {
        guard currentUser?.isTwitterLogin == true, let uid = currentUser?.firebaseAuthUser?.uid else {
            BookmarkDispatcher.updateState(c: category, s: .failure(.needTwitterAuth(nil)))
            return
        }

        BookmarkDispatcher.updateState(c: category, s: .loading)
        UserDispatcher.kickTwitterTimelineScrape(uid: uid, maxId: nil) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let error):
                BookmarkDispatcher.updateState(c: self.category, s: .failure(error))
            case .success(_):
                BookmarkDispatcher.fetchBookmark(
                    category: .timeline,
                    uid: uid,
                    type: .new(limit: 30),
                    commentCountOffset: 0
                ) { _ in }
            }
        }
    }

    @objc
    func refreshCheck() {
        guard let last = lastRefreshCheckAt else { return }
        if last.addingTimeInterval(TimeInterval(30 * 60)) < Date() {
            fetchBookmark()
        }
    }
}

extension CategoryArticleListViewModel: StoreSubscriber {
    struct Props {
        let responseData: Repository.Result<[Bookmark]>?
        let responseState: Repository.ResponseState
        let currentUser: TwibuUser
        let webArchiveResults: [(String, WebArchiver.SaveResult)]
        let twitterMaxId: String?
        let lastRefreshCheckAt: Date?
    }

    typealias StoreSubscriberStateType = Props

    func newState(state: Props) {
        let oldResponseState = responseState
        currentUser = state.currentUser
        twitterMaxId = state.twitterMaxId
        lastRefreshCheckAt = state.lastRefreshCheckAt
        responseState = state.responseState

        switch responseState {
        case .notYetLoading:
            // 初回取得前はここを通る
            delegate?.render(state: .notYetLoading)
            fetchBookmark()
            return
        case .failure, .loading, .additionalLoading, .success:
            if isResponseChanged(old: responseData, new: state.responseData) {
                responseData = state.responseData
                render()
            }
        }

        if !Repository.ResponseState.isEqual(a: oldResponseState, b: responseState) {
            render()
        }

        let changed = changedResults(
            a: webArchiveResults,
            b: state.webArchiveResults
        )
        if !changed.isEmpty {
            webArchiveResults = state.webArchiveResults
            delegate?.update(results: changed)
        }
    }

    private func render() {
        DispatchQueue.main.async {
            self.delegate?.render(state: self.convert(self.responseState))
        }
    }

    private func isResponseChanged(
        old: Repository.Result<[Bookmark]>?,
        new: Repository.Result<[Bookmark]>?
    ) -> Bool {
        if old == nil, new == nil {
            return false
        }
        if !Bookmark.isEqual(a: old?.item ?? [], b: new?.item ?? []) {
            return true
        }
        if old?.hasMore != new?.hasMore {
            return true
        }
        return false
    }

    private func changedResults(
        a: [(String, WebArchiver.SaveResult)],
        b: [(String, WebArchiver.SaveResult)]
    ) -> [(String, WebArchiver.SaveResult)] {
        let aKeys = a.map { $0.0 }
        let bKeys = b.map { $0.0 }

        let changedUids = bKeys.filter { bKey in
            guard let depKey = aKeys.first(where: { $0 == bKey }) else {
                return true
            }

            guard let aResult = a.first(where: { $0.0 == depKey }),
                let bResult = b.first(where: { $0.0 == depKey }) else {
                    return true
            }

            switch aResult.1 {
            case .success:
                switch bResult.1 {
                case .success:
                    return false
                default:
                    return true
                }
            case .progress(let aProgress):
                switch bResult.1 {
                case .progress(let bProgress):
                    if aProgress == bProgress {
                        return false
                    }
                    return true
                default:
                    return true
                }
            case .failure(_):
                switch bResult.1 {
                case .failure(_):
                    return false
                default:
                    return true
                }
            }
        }

        return b.filter { changedUids.contains($0.0) }
    }

    private func convert(_ state: Repository.ResponseState) -> ArticleRenderState {
        switch state {
        case .success:
            return .success
        case .loading:
            return .loading
        case .additionalLoading:
            return .additionalLoading
        case .failure(let error):
            return .failure(error: error)
        case .notYetLoading:
            return .notYetLoading
        }
    }
}
