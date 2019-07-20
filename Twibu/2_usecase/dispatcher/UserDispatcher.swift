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
import TwitterKit
import Crashlytics
import Embedded

struct UserDispatcher {
    static func linkTwitterAccount(user: User, session: TWTRSession, completion: @escaping (Result<Void>) -> Void) {
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
        TwibuUserDefaults.shared.setFirebaseUid(uid: user.uid)
        Crashlytics.sharedInstance().setUserIdentifier(user.uid)

        let twitterLinked = TwibuUser.isTwitterLogin(user: user)
        Analytics.setUserProperty(twitterLinked ? "1" : "0", forName: "twitterLinked")

        // twitterログインしているならtimelineの情報を更新する
        if twitterLinked {
            updateTimeline(uid: user.uid)
        }
    }

    private static func updateTimeline(uid: String) {
        // timelineそのものを更新
        UserRepository.kickScrapeTimeline(uid: uid) { _ in
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

            UserRepository.deleteTwitterToken(uid: nu.uid)
            updateFirebaseUser(user: nu)
            completion(.success(Void()))
        }
    }
}
