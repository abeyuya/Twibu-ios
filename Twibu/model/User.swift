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

final class User {
    private static let db = Firestore.firestore()
    private static let functions = Functions.functions()
    private static let path = "users"

    static func add(
        user: FirebaseAuth.User,
        accessToken: String,
        secretToken: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let data: [String: String] = [
            "uid": user.uid,
            "access_token": accessToken,
            "secret_token": secretToken
        ]

        db.collection(path)
            .document(user.uid)
            .setData(data, merge: true) { error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                completion(.success(Void()))
        }
    }

    static func kickScrapeTimeline(uid: String, completion: @escaping (Result<HTTPSCallableResult?, Error>) -> Void) {
        let data = ["uid": uid]
        functions.httpsCallable("execFetchUserTimeline").call(data) { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            completion(.success(result))
        }
    }

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
