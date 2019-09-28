//
//  MemoDispatcher.swift
//  Twibu
//
//  Created by abeyuya on 2019/08/03.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import Foundation
import FirebaseFirestore
import Embedded

enum MemoDispatcher {
    static func deleteMemo(
        userUid: String,
        bookmarkUid: String,
        completion: @escaping (Result<Void>) -> Void
    ) {
        MemoRepository.deleteMemo(userUid: userUid, bookmarkUid: bookmarkUid) { result in
            switch result {
            case .failure(let e):
                completion(.failure(e))
            case .success(_):
                let a = RemoveBookmarkAction(category: .memo, bookmarkUid: bookmarkUid)
                store.mDispatch(a)
                completion(.success(Void()))
            }
        }
    }
}
