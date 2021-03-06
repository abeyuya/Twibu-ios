//
//  MemoArticleListViewModel.swift
//  Twibu
//
//  Created by abeyuya on 2019/09/22.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import Embedded
import ReSwift

final class MemoArticleListViewModel: ArticleList {
    internal weak var delegate: ArticleListDelegate?
    private var responseData: Repository.Result<[MemoReducer.Info]>?
    private var responseState: Repository.ResponseState = .notYetLoading

    var type: ArticleListType {
        return .memo
    }
    var currentUser: TwibuUser?
    var bookmarks: [Bookmark] {
        return responseData?.item.compactMap { $0.bookmark } ?? []
    }
    var webArchiveResults: [(String, WebArchiver.SaveResult)] = []

    init(delegate: ArticleListDelegate, type: ArticleListType) {
        self.delegate = delegate
    }
}

// input
extension MemoArticleListViewModel {
    func startSubscribe() {
        store.subscribe(self) { subcription in
            subcription.select { state in
                return Props(
                    responseData: state.memo.result,
                    responseState: state.memo.state,
                    currentUser: state.currentUser
                )
            }
        }
    }

    func stopSubscribe() {
        store.unsubscribe(self)
    }

    func fetchBookmark() {
        guard let uid = currentUser?.firebaseAuthUser?.uid else { return }

        MemoDispatcher.fetchMemos(
            userUid: uid,
            type: .new(limit: 30)
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
            case .history, .category, .timeline:
                assertionFailure("通らないはず")
                break
            case .memo:
                guard let uid = currentUser?.firebaseAuthUser?.uid, responseData?.hasMore == true else { return }
                MemoDispatcher.fetchMemos(
                    userUid: uid,
                    type: .add(limit: 30, pagingInfo: responseData?.pagingInfo)
                )
            }
        }
    }

    func deleteBookmark(bookmarkUid: String, completion: @escaping (Result<Void, TwibuError>) -> Void) {
        guard let uid = currentUser?.firebaseAuthUser?.uid else { return }
        MemoDispatcher.deleteMemo(userUid: uid, bookmarkUid: bookmarkUid, completion: completion)
    }
}

extension MemoArticleListViewModel: StoreSubscriber {
    struct Props {
        let responseData: Repository.Result<[MemoReducer.Info]>?
        let responseState: Repository.ResponseState
        let currentUser: TwibuUser
    }

    typealias StoreSubscriberStateType = Props

    func newState(state: Props) {
        let oldResponseState = responseState
        currentUser = state.currentUser
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
            if oldResponseState != responseState {
                responseData = state.responseData
                render()
            }
        }

        if oldResponseState != responseState {
            render()
        }
    }

    private func render() {
        DispatchQueue.main.async {
            self.delegate?.render(state: self.convert(self.responseState))
        }
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
