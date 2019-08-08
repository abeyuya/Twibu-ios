//
//  ArticleListProtocol.swift
//  Twibu
//
//  Created by abeyuya on 2019/08/08.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import Embedded

enum RenderState {
    case success(hasMore: Bool), failure(error: TwibuError), loading, notYetLoading
}

enum ArticleListType {
    case category(Embedded.Category)
}

protocol ArticleListDelegate: class {
    func render(state: RenderState)
}

protocol ArticleList {
    var delegate: ArticleListDelegate? { get }
    var currentUser: TwibuUser? { get }
    var bookmarks: [Bookmark] { get }
    var type: ArticleListType { get }

    // input
    func set(delegate: ArticleListDelegate, type: ArticleListType)
    func startSubscribe()
    func stopSubscribe()
    func fetchBookmark()
    func fetchAdditionalBookmarks()
}
