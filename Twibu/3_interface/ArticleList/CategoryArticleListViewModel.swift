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
        case .history, .memo, .timeline:
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
        )
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
            case .history, .memo, .timeline:
                assertionFailure("通らないはず")
                break
            case .category:
                let d: Repository.Result<[Bookmark]> = {
                    if let d = responseData {
                        return d
                    }
                    return .init(item: [], pagingInfo: nil, hasMore: true)
                }()
                fetchAdditionalForAllCategory(result: d)
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
        )
    }

    func deleteBookmark(bookmarkUid: String, completion: @escaping (Result<Void>) -> Void) {
        assertionFailure("来ないはず")
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
            render()
            fetchBookmark()
            return
        case .failure, .loading, .additionalLoading:
            if Repository.ResponseState.isEqual(a: oldResponseState, b: responseState) {
                return
            }
        case .success:
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
        let a = old?.item ?? []
        let b = new?.item ?? []
        if a != b {
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
