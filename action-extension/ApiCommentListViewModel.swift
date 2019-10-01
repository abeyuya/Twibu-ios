//
//  ApiCommentListViewModel.swift
//  action-extension
//
//  Created by abeyuya on 2019/09/23.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import Embedded

final class ApiCommentListViewModel: CommentList {
    private var response: CommentRepositoryApi.ApiResponse?
    private var comments: [Comment] {
        return response?.comments ?? []
    }

    weak var delegate: CommentListDelegate?
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

extension ApiCommentListViewModel {
    func set(delegate: CommentListDelegate, type: CommentType, bookmark: Bookmark) {
        self.delegate = delegate
        self.commentType = type
        self.bookmark = bookmark
    }

    func startSubscribe() {
        fetchComments()
    }

    func stopSubscribe() {
    }

    func fetchComments() {
        guard let res = CommentRepositoryApi.shared.getResponse() else {
            delegate?.render(state: .failure(error: .apiError("レスポンスがありません")))
            return
        }
        response = res
        delegate?.render(state: .success)
    }

    func fetchAdditionalComments() {
    }

    func didTapComment(comment: Comment) {
        delegate?.openExternalLink(comment: comment)
    }
}
