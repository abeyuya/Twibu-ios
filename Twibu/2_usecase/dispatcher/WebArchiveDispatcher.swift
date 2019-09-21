//
//  WebArchiveDispatcher.swift
//  Twibu
//
//  Created by abeyuya on 2019/09/06.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import Embedded
import WebKit

enum WebArchiveDispatcher {
    static func save(
        webView: WKWebView,
        bookmarkUid: String,
        callback: @escaping (WebArchiver.SaveResult) -> Void
    ) {
        if let r = store.state.webArchive.results.first(where: { $0.bookmarkUid == bookmarkUid}) {
            switch r.result {
            case .success, .progress(_): // 既に保存済み or 保存中なら何もしない
                return
            case .failure(_):
                break
            }
        }

        WebArchiver.save(webView: webView, bookmarkUid: bookmarkUid) { result in
            WebArchiveDispatcher.update(bookmarkUid: bookmarkUid, result: result)
            callback(result)
        }
//        let a = AddWebArchiveTask(webArchiver: t)
//        store.mDispatch(a)
    }

    static func update(bookmarkUid: String, result: WebArchiver.SaveResult) {
        let a = UpdateWebArchiveResult(bookmarkUid: bookmarkUid, result: result)
        store.mDispatch(a)
    }
}
