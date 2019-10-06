//
//  TimelineArticleListViewModel.swift
//  Twibu
//
//  Created by abeyuya on 2019/10/03.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import Embedded
import ReSwift

final class TimelineArticleListViewModel: ArticleList {
    internal weak var delegate: ArticleListDelegate?
    private var responseData: Repository.Result<[TimelineReducer.Info]>?
    private var responseState: Repository.ResponseState = .notYetLoading

    var type: ArticleListType {
        return .timeline
    }
    var currentUser: TwibuUser?
    var bookmarks: [Bookmark] {
        return responseData?.item.compactMap { $0.bookmark } ?? []
    }
    var timelines: [Timeline] {
        return responseData?.item.compactMap { $0.timeline } ?? []
    }
    var webArchiveResults: [(String, WebArchiver.SaveResult)] = []
    var twitterMaxId: String?
    var lastRefreshCheckAt: Date?
}

// input
extension TimelineArticleListViewModel {
    func set(delegate: ArticleListDelegate, type: ArticleListType) {
        self.delegate = delegate
    }

    func startSubscribe() {
        store.subscribe(self) { subcription in
            subcription.select { state in
                return Props(
                    responseData: state.timeline.result,
                    responseState: state.timeline.state,
                    currentUser: state.currentUser,
                    webArchiveResults: state.webArchive.results,
                    twitterMaxId: state.timeline.twitterTimelineMaxId,
                    lastRefreshCheckAt: state.timeline.lastRefreshAt
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
        guard currentUser?.isTwitterLogin == true, let uid = currentUser?.firebaseAuthUser?.uid else {
            TimelineDispatcher.updateState(s: .failure(.needTwitterAuth(nil)))
            return
        }

        TimelineDispatcher.updateState(s: .loading)
        UserDispatcher.kickTwitterTimelineScrape(uid: uid, maxId: nil) { result in
            switch result {
            case .failure(let error):
                TimelineDispatcher.updateState(s: .failure(error))
            case .success(_):
                TimelineDispatcher.fetchTimeline(
                    userUid: uid,
                    type: .new(limit: 30)
                ) { _ in }
            }
        }
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
            let d: Repository.Result<[TimelineReducer.Info]> = {
                if let d = responseData {
                    return d
                }
                return .init(item: [], pagingInfo: nil, hasMore: true)
            }()
            fetchAdditionalForTimeline(result: d)
        }
    }

    private func fetchAdditionalForTimeline(result: Repository.Result<[TimelineReducer.Info]>) {
        guard let uid = currentUser?.firebaseAuthUser?.uid else { return }
        if result.hasMore {
            TimelineDispatcher.fetchTimeline(
                userUid: uid,
                type: .add(limit: 30, pagingInfo: result.pagingInfo)
            ) { _ in }
            return
        }

        // NOTE: onCreateBookmark完了まで待ちたいので、loadingを発行しておく
        TimelineDispatcher.updateState(s: .additionalLoading)

        UserDispatcher.kickTwitterTimelineScrape(uid: uid, maxId: twitterMaxId) { [weak self] kickResult in
            guard let self = self else { return }
            switch kickResult {
            case .failure(let e):
                TimelineDispatcher.updateState(s: .failure(e))
                self.delegate?.render(state: .failure(error: e))
            case .success(_):
                TimelineDispatcher.updateState(s: .success)
                DispatchQueue.main.async {
                    let r = Repository.Result<[TimelineReducer.Info]>(
                        item: result.item,
                        pagingInfo: result.pagingInfo,
                        hasMore: true // これを渡したい
                    )
                    self.fetchAdditionalForTimeline(result: r)
                }
            }
        }
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

extension TimelineArticleListViewModel: StoreSubscriber {
    struct Props {
        let responseData: Repository.Result<[TimelineReducer.Info]>?
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
            if oldResponseState == responseState {
                return
            }
        case .success:
            if isResponseChanged(old: responseData, new: state.responseData) {
                responseData = state.responseData
                render()
            }
        }

        if oldResponseState != responseState {
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
        old: Repository.Result<[TimelineReducer.Info]>?,
        new: Repository.Result<[TimelineReducer.Info]>?
    ) -> Bool {
        let a = old?.item.compactMap { $0 } ?? []
        let b = new?.item.compactMap { $0 } ?? []
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
