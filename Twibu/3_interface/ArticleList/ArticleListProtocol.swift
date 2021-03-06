//
//  ArticleListProtocol.swift
//  Twibu
//
//  Created by abeyuya on 2019/08/08.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import Embedded

enum ArticleRenderState {
    case success
    case failure(error: TwibuError)
    case loading
    case additionalLoading
    case notYetLoading
}

enum ArticleListType {
    case category(Embedded.Category)
    case history
    case memo
    case timeline
}

protocol ArticleListDelegate: class {
    func render(state: ArticleRenderState)
    func update(results: [(String, WebArchiver.SaveResult)])
}

protocol ArticleList {
    var delegate: ArticleListDelegate? { get }
    var currentUser: TwibuUser? { get }
    var bookmarks: [Bookmark] { get }
    var type: ArticleListType { get }
    var webArchiveResults: [(String, WebArchiver.SaveResult)] { get }

    init(delegate: ArticleListDelegate, type: ArticleListType)

    // input
    func startSubscribe()
    func stopSubscribe()
    func fetchBookmark()
    func fetchAdditionalBookmarks()
    func deleteBookmark(bookmarkUid: String, completion: @escaping (Result<Void, TwibuError>) -> Void)
}
