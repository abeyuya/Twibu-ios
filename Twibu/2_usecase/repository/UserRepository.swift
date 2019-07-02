//
//  User.swift
//  Twibu
//
//  Created by abeyuya on 2019/06/16.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import FirebaseAuth
import FirebaseFirestore
import FirebaseFunctions

final class UserRepository {
    private static let db = TwibuFirebase.firestore
    private static let functions = TwibuFirebase.functions
    private static let path = "users"

    static func add(
        uid: String,
        userName: String,
        userId: String,
        accessToken: String,
        secretToken: String,
        completion: @escaping (Result<Void>) -> Void
    ) {
        let data: [String: Any] = [
            "uid": uid,
            "user_id": userId,
            "user_name": userName,
            "access_token": accessToken,
            "secret_token": secretToken,
            "created_at": FieldValue.serverTimestamp()
        ]

        db.collection(path)
            .document(uid)
            .setData(data, mergeFields: ["access_token", "secret_token"]) { error in
                if let error = error {
                    completion(.failure(.firestoreError(error.localizedDescription)))
                    return
                }
                completion(.success(Void()))
        }
    }

    static func kickScrapeTimeline(uid: String, completion: @escaping (Result<HTTPSCallableResult?>) -> Void) {
        let data: [String: String] = ["uid": uid]
        functions.httpsCallable("execFetchUserTimeline").call(data) { result, error in
            if let error = error {
                completion(.failure(.firebaseFunctionsError(error.localizedDescription)))
                return
            }
            completion(.success(result))
        }
    }

//    static func isTwitterLogin() -> Bool {
//        guard let user = Auth.auth().currentUser else {
//            return false
//        }
//
//        if user.providerData.isEmpty {
//            return false
//        }
//
//        return true
//    }

//    static func fetchTimeline(page: Int = 1, completion: @escaping (Result<Void, Error>) -> Void) {
//        guard let currentUser = Auth.auth().currentUser else {
//            let error = NSError(domain: "", code: 400, userInfo: ["message": "ログインしてください"])
//            completion(.failure(error))
//            return
//        }
//
//        db.collection(path)
//            .document(currentUser.uid)
//            .collection("timeline")
//            .order(by: "created_at")
//            .limit(to: 30)
//            .addSnapshotListener() { snapshot, error in
//
//        }
//    }
}
