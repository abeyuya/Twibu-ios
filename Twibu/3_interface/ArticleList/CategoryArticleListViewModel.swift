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
    private var response: Repository.Response<[Bookmark]> = .notYetLoading
    private var category: Embedded.Category {
        switch type {
        case .category(let c):
            return c
        case .history:
            assertionFailure("来ないはず")
            return .all
        }
    }

    var type: ArticleListType = .category(.all)
    var currentUser: TwibuUser?
    var bookmarks: [Bookmark] {
        return response.item ?? []
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
                let res: Repository.Response<[Bookmark]>? = {
                    guard let c = self?.category else { return nil }
                    return state.response.bookmarks[c]
                }()

                return Props(
                    res: res,
                    currentUser: state.currentUser,
                    webArchiveResults: state.webArchive.results,
                    twitterMaxId: state.twitterTimelineMaxId,
                    lastRefreshCheckAt: {
                        guard let c = self?.category else { return nil }
                        return state.lastRefreshAt[c]
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

    func fetchBookmark(completion: @escaping (Result<[Bookmark]>) -> Void) {
        guard let uid = currentUser?.firebaseAuthUser?.uid else { return }

        if category == .timeline, currentUser?.isTwitterLogin == true {
            refreshForLoginUser(completion: completion)
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
        switch response {
        case .loading(_):
            return
        case .notYetLoading:
            // view読み込み時だけ通る
            return
        case .failure(_):
            return
        case .success(let result):
            switch type {
            case .history:
                assertionFailure("通らないはず")
                break
            case .category(let c):
                switch c {
                case .timeline:
                    fetchAdditionalForTimeline(result: result)
                default:
                    fetchAdditionalForAllCategory(result: result)
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
        BookmarkDispatcher.setLoading(c: category)

        UserDispatcher.kickTwitterTimelineScrape(uid: uid, maxId: twitterMaxId) { [weak self] kickResult in
            switch kickResult {
            case .failure(let e):
                Logger.print(e.displayMessage)
            case .success(_):
                DispatchQueue.main.async {
                    let r = Repository.Result<[Bookmark]>(
                        item: result.item,
                        pagingInfo: result.pagingInfo,
                        hasMore: true // これを渡したい
                    )
                    self?.fetchAdditionalForAllCategory(result: r)
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
        switch type {
        case .history:
            break
        case .category(let c):
            guard c == .memo else { return }
            guard let uid = currentUser?.firebaseAuthUser?.uid else { return }
            MemoDispatcher.deleteMemo(userUid: uid, bookmarkUid: bookmarkUid, completion: completion)
        }
    }

    private func refreshForLoginUser(completion: @escaping (Result<[Bookmark]>) -> Void) {
        guard currentUser?.isTwitterLogin == true, let uid = currentUser?.firebaseAuthUser?.uid else {
            completion(.failure(TwibuError.needTwitterAuth(nil)))
            return
        }

        UserDispatcher.kickTwitterTimelineScrape(uid: uid, maxId: nil) { [weak self] result1 in
            switch result1 {
            case .failure(let error):
                completion(.failure(error))
            case .success(_):
                self?.fetchBookmark(completion: completion)
            }
        }
    }

    @objc
    func refreshCheck() {
        guard let last = lastRefreshCheckAt else { return }
        if last.addingTimeInterval(TimeInterval(30 * 60)) < Date() {
            fetchBookmark() { _ in }
        }
    }
}

extension CategoryArticleListViewModel: StoreSubscriber {
    struct Props {
        var res: Repository.Response<[Bookmark]>?
        var currentUser: TwibuUser
        var webArchiveResults: [(String, WebArchiver.SaveResult)]
        var twitterMaxId: String?
        var lastRefreshCheckAt: Date?
    }

    typealias StoreSubscriberStateType = Props

    func newState(state: Props) {
        currentUser = state.currentUser
        twitterMaxId = state.twitterMaxId
        lastRefreshCheckAt = state.lastRefreshCheckAt

        guard let res = state.res else {
            // 初回取得前はここを通る
            response = .notYetLoading
            delegate?.render(state: .notYetLoading)
            fetchBookmark { _ in }
            return
        }

        response = res
        delegate?.render(state: convert(res))

        let changed = changedResults(
            a: webArchiveResults,
            b: state.webArchiveResults
        )
        if !changed.isEmpty {
            webArchiveResults = state.webArchiveResults
            delegate?.update(results: changed)
        }
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

    private func convert(_ res: Repository.Response<[Bookmark]>) -> ArticleRenderState {
        switch res {
        case .success(let result):
            return .success(hasMore: result.hasMore)
        case .loading(_):
            return .loading
        case .failure(let error):
            return .failure(error: error)
        case .notYetLoading:
            return .notYetLoading
        }
    }
}
