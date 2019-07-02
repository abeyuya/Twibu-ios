//
//  UserDispatcher.swift
//  Twibu
//
//  Created by abeyuya on 2019/07/03.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import Foundation
import FirebaseAuth
import TwitterKit

struct UserDispatcher {
    static func linkTwitterAccount(session: TWTRSession, completion: @escaping (Result<Void>) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(.failure(TwibuError.needFirebaseAuth(nil)))
            return
        }

        let cred = TwitterAuthProvider.credential(
            withToken: session.authToken,
            secret: session.authTokenSecret
        )

        user.link(with: cred) { result, error in
            if let error = error {
                completion(.failure(TwibuError.twitterLogin(error.localizedDescription)))
                return
            }
            guard let result = result else {
                completion(.failure(TwibuError.twitterLogin("Twitterユーザが取得できませんでした")))
                return
            }

            UserRepository.add(
                uid: result.user.uid,
                userName: session.userName,
                userId: session.userID,
                accessToken: session.authToken,
                secretToken: session.authTokenSecret
            ) { addResult in
                switch addResult {
                case .success:
                    updateFirebaseUser(user: result.user)
                    completion(.success(Void()))
                case .failure(let error):
                    completion(.failure(TwibuError.twitterLogin(error.displayMessage)))
                }
            }
        }
    }

    static func updateFirebaseUser(user: User) {
        let a = UpdateFirebaseUser(newUser: user)
        store.dispatch(a)
    }

    static func unlinkTwitter(user: User, completion: @escaping (Result<Void>) -> Void) {
        user.unlink(fromProvider: "twitter.com") { newUser, error in
            if let error = error {
                completion(.failure(TwibuError.signOut(error.localizedDescription)))
                return
            }

            guard let nu = newUser else {
                completion(.failure(TwibuError.signOut("unlinkできたけどその後userが取れない")))
                return
            }

            // TODO: access_tokenとか使えなくなるので消したい
            updateFirebaseUser(user: nu)
            completion(.success(Void()))
        }
    }
}
