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
import Embedded

enum UserRepository {
    private static let path = "users"

    static func createOrUpdate(
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

        TwibuFirebase.shared.firestore
            .collection(path)
            .document(uid)
            .setData(data, merge: true) { error in
                if let error = error {
                    Logger.print(data)
                    completion(.failure(.firestoreError(error.localizedDescription)))
                    return
                }
                completion(.success(Void()))
        }
    }

    static func kickScrapeTimeline(
        uid: String,
        maxId: String?,
        completion: @escaping (Result<String>) -> Void
    ) {
        var data: [String: String] = ["uid": uid]
        if let m = maxId {
            data["max_id"] = m
        }
        TwibuFirebase.shared.functions
            .httpsCallable("execFetchUserTimeline")
            .call(data) { result, error in
                if let error = error {
                    if TwibuError.isTwitterRateLimit(error: error) {
                        completion(.failure(.twitterRateLimit(error.localizedDescription)))
                    } else {
                        completion(.failure(.firebaseFunctionsError(error.localizedDescription)))
                    }
                    return
                }
                guard let d = result?.data as? [String: Any] else {
                    completion(.failure(.firebaseFunctionsError("data取れず")))
                    return
                }
                guard let maxId = d["max_id"] as? String else {
                    completion(.failure(.firebaseFunctionsError("data取れず")))
                    return
                }
                completion(.success(maxId))
        }
    }

    static func deleteTwitterToken(uid: String) {
        let data: [String: Any] = [
            "access_token": FieldValue.delete(),
            "secret_token": FieldValue.delete(),
            "updated_at": FieldValue.serverTimestamp()
        ]
        TwibuFirebase.shared.firestore
            .collection(path)
            .document(uid)
            .updateData(data)
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
