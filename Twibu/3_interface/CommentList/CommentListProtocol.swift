//
//  CommentListProtocol.swift
//  Twibu
//
//  Created by abeyuya on 2019/09/23.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import Embedded

enum CommentRenderState {
    case success(hasMore: Bool), failure(error: TwibuError), loading, notYetLoading
}

protocol CommentListDelegate: class {
    func render(state: CommentRenderState)
}

enum CommentType {
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

protocol CommentList {
    var delegate: CommentListDelegate? { get }
    var currentUser: TwibuUser? { get }
    var bookmark: Bookmark? { get }
    var commentType: CommentType { get }
    var currentComments: [Comment] { get }

    // input
    func set(delegate: CommentListDelegate, type: CommentType, bookmark: Bookmark)
    func startSubscribe()
    func stopSubscribe()
    func fetchComments()
    func fetchAdditionalComments()
}
