//
//  CommentListProtocol.swift
//  Twibu
//
//  Created by abeyuya on 2019/09/23.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import Foundation

public enum CommentRenderState {
    case success(hasMore: Bool), failure(error: TwibuError), loading, notYetLoading
}

public protocol CommentListDelegate: class {
    func render(state: CommentRenderState)
    func openAdminMenu(comment: Comment)
    func openExternalLink(comment: Comment)
}

public enum CommentType {
    case left, right

    var title: String {
        switch self {
        case .left:
            return "みんなのコメント"
        case .right:
            return "その他のツイート"
        }
    }
}

public protocol CommentList {
    var delegate: CommentListDelegate? { get }
    var bookmark: Bookmark? { get }
    var commentType: CommentType { get }
    var currentComments: [Comment] { get }

    init()

    // input
    func set(delegate: CommentListDelegate, type: CommentType, bookmark: Bookmark)
    func startSubscribe()
    func stopSubscribe()
    func fetchComments()
    func fetchAdditionalComments()
    func didTapComment(comment: Comment)
}
