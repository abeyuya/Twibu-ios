//
//  User.swift
//  Twibu
//
//  Created by abeyuya on 2019/06/16.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import FirebaseAuth
import FirebaseFirestore

final class User {
    private static let db = Firestore.firestore()
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
}
