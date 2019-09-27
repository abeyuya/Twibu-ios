//
//  UserDispatcher.swift
//  Twibu
//
//  Created by abeyuya on 2019/07/03.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import Foundation
import FirebaseAuth
import FirebaseAnalytics
import FirebaseFirestore
import FirebaseFunctions
import Swifter
import Crashlytics
import Embedded

enum UserDispatcher {
    static func setupUser(completion: @escaping (Result<Void>) -> Void) {
        if let user = Auth.auth().currentUser {
            updateFirebaseUser(firebaseUser: user)
            completion(.success(Void()))
            return
        }

        Auth.auth().signInAnonymously() { result, error in
            if let error = error {
                let e = TwibuError.needFirebaseAuth(error.localizedDescription)
                completion(.failure(e))
                return
            }

            guard let user = result?.user else {
                let e = TwibuError.needFirebaseAuth("匿名ログインしたもののユーザ情報が取れない")
                completion(.failure(e))
                return
            }

            UserDispatcher.updateFirebaseUser(firebaseUser: user)
            completion(.success(Void()))
        }
    }

    static func loginAsTwitterAccount(
        anonymousFirebaseUser: User,
        session: Credential.OAuthAccessToken,
        completion: @escaping (Result<Void>) -> Void
    ) {
        //
        // TODO: ログアウトする前に、現在ログイン中の匿名ユーザのメモとかの情報をTwitterアカウントの方に移植したい
        //
        do {
            try Auth.auth().signOut()
        } catch let error {
            completion(.failure(TwibuError.unknown(error.localizedDescription)))
            return
        }

        let cred = TwitterAuthProvider.credential(
            withToken: session.key,
            secret: session.secret
        )

        Auth.auth().signIn(with: cred) { result, error in
            if let error = error {
                if (error as NSError).code == TwibuError.alreadyExistTwitterAccountErrorCode {
                    completion(.failure(TwibuError.twitterLoginAlreadyExist(error.localizedDescription)))
                } else {
                    completion(.failure(TwibuError.twitterLogin(error.localizedDescription)))
                }
                return
            }
            guard let result = result else {
                completion(.failure(TwibuError.twitterLogin("Twitterユーザが取得できませんでした")))
                return
            }

            UserRepository.createOrUpdate(
                uid: result.user.uid,
                userName: session.screenName ?? "",
                userId: session.userID ?? "",
                accessToken: session.key,
                secretToken: session.secret
            ) { addResult in
                switch addResult {
                case .success:
                    updateFirebaseUser(firebaseUser: result.user)
                    completion(.success(Void()))
                case .failure(let error):
                    completion(.failure(TwibuError.twitterLogin(error.displayMessage)))
                }
            }
        }
    }

    static func linkTwitterAccount(
        firebaseUser: User,
        session: Credential.OAuthAccessToken,
        completion: @escaping (Result<Void>) -> Void
    ) {
        let cred = TwitterAuthProvider.credential(
            withToken: session.key,
            secret: session.secret
        )

        firebaseUser.link(with: cred) { result, error in
            if let error = error {
                if (error as NSError).code == TwibuError.alreadyExistTwitterAccountErrorCode {
                    completion(.failure(TwibuError.twitterLoginAlreadyExist(error.localizedDescription)))
                } else {
                    completion(.failure(TwibuError.twitterLogin(error.localizedDescription)))
                }
                return
            }
            guard let result = result else {
                completion(.failure(TwibuError.twitterLogin("Twitterユーザが取得できませんでした")))
                return
            }

            UserRepository.createOrUpdate(
                uid: result.user.uid,
                userName: session.screenName ?? "",
                userId: session.userID ?? "",
                accessToken: session.key,
                secretToken: session.secret
            ) { addResult in
                switch addResult {
                case .success:
                    updateFirebaseUser(firebaseUser: result.user)
                    completion(.success(Void()))
                case .failure(let error):
                    completion(.failure(TwibuError.twitterLogin(error.displayMessage)))
                }
            }
        }
    }

    static func updateFirebaseUser(firebaseUser: User) {
        let a = UpdateFirebaseUserAction(newUser: firebaseUser)
        store.dispatch(a)
        TwibuUserDefaults.shared.setFirebaseUid(uid: firebaseUser.uid)
        Crashlytics.sharedInstance().setUserIdentifier(firebaseUser.uid)

        let twitterLinked = TwibuUser.isTwitterLogin(user: firebaseUser)
        Analytics.setUserProperty(twitterLinked ? "1" : "0", forName: "twitterLinked")

        // twitterログインしているならtimelineの情報を更新する
        if twitterLinked {
            updateTimeline(uid: firebaseUser.uid)
        }
    }

    private static func updateTimeline(uid: String) {
        // timelineそのものを更新
        UserRepository.kickScrapeTimeline(uid: uid) { _ in
            // timelineのbookmarkを取得
            BookmarkDispatcher.fetchBookmark(
                category: .timeline,
                uid: uid,
                type: .new(limit: 20),
                commentCountOffset: 0
            ) { result in
                switch result {
                case .failure(let error):
                    Logger.print(error)
                case .success(_):
                    break
                    // それぞれ最新のコメントに更新
//                    bookmarks.forEach { b in
//                        CommentDispatcher.updateAndFetchComments(
//                            buid: b.uid,
//                            title: b.title ?? "",
//                            url: b.url,
//                            type: .new
//                        )
//                    }
                }
            }
        }
    }

    static func unlinkTwitter(firebaseUser: User, completion: @escaping (Result<Void>) -> Void) {
        firebaseUser.unlink(fromProvider: "twitter.com") { newUser, error in
            if let error = error {
                completion(.failure(TwibuError.signOut(error.localizedDescription)))
                return
            }

            guard let nu = newUser else {
                completion(.failure(TwibuError.signOut("unlinkできたけどその後userが取れない")))
                return
            }

            UserRepository.deleteTwitterToken(uid: nu.uid)
            updateFirebaseUser(firebaseUser: nu)
            completion(.success(Void()))
        }
    }
}
