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
    private var response: Repository.Response<[Comment]> = .notYetLoading
    private var comments: [Comment] {
        return response.item ?? []
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
                let res: Repository.Response<[Comment]>? = {
                    guard let buid = self?.bookmark?.uid else { return nil }
                    guard let res = state.response.comments[buid] else { return nil }
                    return res
                }()

                return Props(res: res, currentUser: state.currentUser)
            }
        }
    }

    func stopSubscribe() {
        store.unsubscribe(self)
    }

    func fetchComments() {
        guard let buid = bookmark?.uid, buid != "" else { return }
        CommentDispatcher.fetchComments(
            repo: CommentRepositoryFirestore.shared,
            buid: buid,
            type: .new(limit: 100)
        )
    }

    func fetchAdditionalComments() {
        switch response {
        case .loading(_):
            return
        case .notYetLoading:
            // 来ないはず
            return
        case .failure(_):
            return
        case .success(let result):
            guard let buid = bookmark?.uid, result.hasMore else {
                return
            }

            CommentDispatcher.fetchComments(
                repo: CommentRepositoryFirestore.shared,
                buid: buid,
                type: .add(limit: 100, pagingInfo: result.pagingInfo)
            )
        }
    }
}

extension FirestoreCommentListViewModel: StoreSubscriber {
    struct Props {
        var res: Repository.Response<[Comment]>?
        var currentUser: TwibuUser?
    }

    typealias StoreSubscriberStateType = Props

    func newState(state: Props) {
        currentUser = state.currentUser

        guard let res = state.res else {
            // 初回取得前はここを通る
            response = .notYetLoading
            delegate?.render(state: .notYetLoading)
            fetchComments()
            return
        }

        guard isResponseChanged(old: response, new: res) else {
            return
        }

        response = res

        DispatchQueue.main.async {
            self.delegate?.render(state: self.convert(res))
        }
    }

    private func isResponseChanged(
        old: Repository.Response<[Comment]>,
        new: Repository.Response<[Comment]>
    ) -> Bool {
        switch old {
        case .loading(_):
            switch new {
            case .loading(_):
                return false
            default:
                return true
            }
        case .failure(_):
            switch new {
            case .failure(_):
                return false
            default:
                return true
            }
        case .notYetLoading:
            switch new {
            case .notYetLoading:
                return false
            default:
                return true
            }
        case .success(let oldResult):
            switch new {
            case .success(let newResult):
                if Comment.isEqual(a: oldResult.item, b: newResult.item) {
                    return false
                }

                return true
            default:
                return true
            }
        }
    }

    private func convert(_ res: Repository.Response<[Comment]>) -> CommentRenderState {
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
