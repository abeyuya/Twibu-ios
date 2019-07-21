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
import TwitterKit
import Crashlytics
import Embedded

struct UserDispatcher {
    static func linkTwitterAccount(db: Firestore, functions: Functions, user: User, session: TWTRSession, completion: @escaping (Result<Void>) -> Void) {
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
                db: db,
                uid: result.user.uid,
                userName: session.userName,
                userId: session.userID,
                accessToken: session.authToken,
                secretToken: session.authTokenSecret
            ) { addResult in
                switch addResult {
                case .success:
                    updateFirebaseUser(functions: functions, user: result.user)
                    completion(.success(Void()))
                case .failure(let error):
                    completion(.failure(TwibuError.twitterLogin(error.displayMessage)))
                }
            }
        }
    }

    static func updateFirebaseUser(functions: Functions, user: User) {
        let a = UpdateFirebaseUser(newUser: user)
        store.dispatch(a)
        TwibuUserDefaults.shared.setFirebaseUid(uid: user.uid)
        Crashlytics.sharedInstance().setUserIdentifier(user.uid)

        let twitterLinked = TwibuUser.isTwitterLogin(user: user)
        Analytics.setUserProperty(twitterLinked ? "1" : "0", forName: "twitterLinked")

        // twitterログインしているならtimelineの情報を更新する
        if twitterLinked {
            updateTimeline(functions: functions, uid: user.uid)
        }
    }

    private static func updateTimeline(functions: Functions, uid: String) {
        // timelineそのものを更新
        UserRepository.kickScrapeTimeline(functions: functions, uid: uid) { _ in
            // timelineのbookmarkを取得
            BookmarkDispatcher.fetchBookmark(category: .timeline, uid: uid, type: .new(20)) { result in
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

    static func unlinkTwitter(db: Firestore, functions: Functions, user: User, completion: @escaping (Result<Void>) -> Void) {
        user.unlink(fromProvider: "twitter.com") { newUser, error in
            if let error = error {
                completion(.failure(TwibuError.signOut(error.localizedDescription)))
                return
            }

            guard let nu = newUser else {
                completion(.failure(TwibuError.signOut("unlinkできたけどその後userが取れない")))
                return
            }

            UserRepository.deleteTwitterToken(db: db, uid: nu.uid)
            updateFirebaseUser(functions: functions, user: nu)
            completion(.success(Void()))
        }
    }
}
