//
//  MemoDispatcher.swift
//  Twibu
//
//  Created by abeyuya on 2019/08/03.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import Embedded

enum MemoDispatcher {
    static func fetchMemos(userUid: String, type: Repository.FetchType) {
        switch type {
        case .add:
            updateState(s: .additionalLoading)
        case .new:
            updateState(s: .loading)
        }

        MemoRepository.fetchMemoBookmarks(userUid: userUid, type: type) { result in
            switch result {
            case .failure(let e):
                updateState(s: .failure(e))
            case .success(let res):
                let a = MemoReducer.Actions.AddMomos(result: res)
                store.mDispatch(a)
                updateState(s: .success)
            }
        }
    }

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
                let a = MemoReducer.Actions.Remove(bookmarkUid: bookmarkUid)
                store.mDispatch(a)
                completion(.success(Void()))
            }
        }
    }

    static func updateState(s: Repository.ResponseState) {
        let a = MemoReducer.Actions.UpdateState(state: s)
        store.mDispatch(a)
    }
}
