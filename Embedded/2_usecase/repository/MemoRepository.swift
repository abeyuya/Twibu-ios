//
//  MemoRepository.swift
//  Embedded
//
//  Created by abeyuya on 2019/08/02.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import Foundation
import FirebaseFirestore

public final class MemoRepository {
    public static func fetchMemo(
        db: Firestore,
        userUid: String,
        bookmarkUid: String,
        completion: @escaping (Result<Memo>) -> Void
    ) {
        db.collection("users")
            .document(userUid)
            .collection("memo")
            .document(bookmarkUid)
            .getDocument() { snapshot, error in
                if let error = error {
                    let e = TwibuError.firestoreError(error.localizedDescription)
                    completion(.failure(e))
                    return
                }

                guard snapshot?.exists ?? false else {
                    completion(.failure(TwibuError.firestoreError("古いメモなし(別にエラーではない)")))
                    return
                }

                guard let dict = snapshot?.data(), let memo = Memo(dictionary: dict) else {
                    completion(.failure(TwibuError.firestoreError("memo decode失敗")))
                    return
                }

                completion(.success(memo))
        }
    }

    public static func saveMemo(
        db: Firestore,
        userUid: String,
        bookmarkUid: String,
        memo: String,
        completion: @escaping (Result<Void>) -> Void
    ) {
        let ref = db.collection("users")
            .document(userUid)
            .collection("memo")
            .document(bookmarkUid)

        let data: [String : Any] = [
            "bookmark_ref": db.collection("bookmarks").document(bookmarkUid),
            "memo": memo,
            "updated_at": FieldValue.serverTimestamp()
        ]

        ref.setData(data) { error in
            if let error = error {
                let e = TwibuError.firestoreError(error.localizedDescription)
                completion(.failure(e))
                return
            }

            completion(.success(Void()))
        }
    }

    public static func deleteMemo(
        db: Firestore,
        userUid: String,
        bookmarkUid: String,
        completion: @escaping (Result<Void>) -> Void
    ) {
        let ref = db.collection("users")
            .document(userUid)
            .collection("memo")
            .document(bookmarkUid)

        ref.delete { error in
            if let error = error {
                let e = TwibuError.firestoreError(error.localizedDescription)
                completion(.failure(e))
                return
            }

            completion(.success(Void()))
        }
    }
}
