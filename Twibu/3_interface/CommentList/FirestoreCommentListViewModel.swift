//
//  FirestoreCommentListViewModel.swift
//  Twibu
//
//  Created by abeyuya on 2019/09/23.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import Embedded
import ReSwift

final class FirestoreCommentListViewModel: CommentList {
    private var responseData: Repository.Result<[Comment]> = .init(item: [], pagingInfo: nil, hasMore: true)
    private var responseState: Repository.ResponseState = .notYetLoading
    private var comments: [Comment] {
        return responseData.item
    }

    weak var delegate: CommentListDelegate?
    var currentUser: TwibuUser?
    var bookmark: Bookmark?
    var commentType: CommentType = .left
    var currentComments: [Comment] {
        switch commentType {
        case .left:
            return comments.filter { $0.has_comment == true }
        case .right:
            return comments.filter { $0.has_comment == nil || $0.has_comment == false }
        }
    }
}

extension FirestoreCommentListViewModel {
    func set(delegate: CommentListDelegate, type: CommentType, bookmark: Bookmark) {
        self.delegate = delegate
        self.commentType = type
        self.bookmark = bookmark
    }

    func startSubscribe() {
        store.subscribe(self) { [weak self] subcription in
            subcription.select { state in
                let data: Repository.Result<[Comment]>? = {
                    guard let buid = self?.bookmark?.uid else { return nil }
                    guard let d = state.responseData.comments[buid] else { return nil }
                    return d
                }()
                let resState: Repository.ResponseState = {
                    guard let buid = self?.bookmark?.uid else { return .notYetLoading }
                    return state.responseState.comments[buid] ?? .notYetLoading
                }()

                return Props(
                    responseData: data,
                    responseState: resState,
                    currentUser: state.currentUser
                )
            }
        }
    }

    func stopSubscribe() {
        store.unsubscribe(self)
    }

    func fetchComments() {
        guard let b = bookmark, b.uid != "" else { return }

        if currentUser?.isTwitterLogin == true {
            CommentDispatcher.updateAndFetchComments(
                buid: b.uid,
                title: b.title ?? "",
                url: b.url,
                type: .new(limit: 100)
            )
            return
        }

        CommentDispatcher.fetchComments(
            buid: b.uid,
            type: .new(limit: 100)
        )
    }

    func fetchAdditionalComments() {
        switch responseState {
        case .loading:
            return
        case .notYetLoading:
            // 来ないはず
            return
        case .failure:
            return
        case .success:
            guard let buid = bookmark?.uid, responseData.hasMore else {
                return
            }

            CommentDispatcher.fetchComments(
                buid: buid,
                type: .add(limit: 100, pagingInfo: responseData.pagingInfo)
            )
        }
    }

    func didTapComment(comment: Comment) {
        if currentUser?.isAdmin == true {
            delegate?.openAdminMenu(comment: comment)
        } else {
            delegate?.openExternalLink(comment: comment)
        }
    }
}

extension FirestoreCommentListViewModel: StoreSubscriber {
    struct Props {
        let responseData: Repository.Result<[Comment]>?
        let responseState: Repository.ResponseState
        let currentUser: TwibuUser?
    }

    typealias StoreSubscriberStateType = Props

    func newState(state: Props) {
        currentUser = state.currentUser
        responseState = state.responseState

        guard let data = state.responseData else {
            // 初回取得前はここを通る
            responseState = .notYetLoading
            delegate?.render(state: .notYetLoading)
            fetchComments()
            return
        }

        guard isResponseChanged(old: responseData, new: data) else {
            return
        }

        responseData = data

        DispatchQueue.main.async {
            self.delegate?.render(state: self.convert(self.responseState))
        }
    }

    private func isResponseChanged(
        old: Repository.Result<[Comment]>,
        new: Repository.Result<[Comment]>
    ) -> Bool {
        if Comment.isEqual(a: old.item, b: new.item) {
            return false
        }
        return true
    }

    private func convert(_ state: Repository.ResponseState) -> CommentRenderState {
        switch state {
        case .success:
            return .success(hasMore: responseData.hasMore)
        case .loading:
            return .loading
        case .failure(let error):
            return .failure(error: error)
        case .notYetLoading:
            return .notYetLoading
        }
    }
}
