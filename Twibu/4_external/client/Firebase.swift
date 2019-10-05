//
//  Firebase.swift
//  Twibu
//
//  Created by abeyuya on 2019/06/27.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import Embedded
import Firebase
import FirebaseFirestore
import FirebaseFunctions

public final class TwibuFirebase {
    public static let shared = TwibuFirebase()
    private init() {
        TwibuFirebase.checkInit()
    }

    private static func checkInit() {
        if FirebaseApp.app() == nil {
            guard let filePath = Bundle.main.path(forResource: "GoogleService-Info-\(Env.current)", ofType: "plist") else {
                assertionFailure("読み込めない！")
                return
            }
            guard let fileopts = FirebaseOptions(contentsOfFile: filePath) else {
                assert(false, "Couldn't load config file")
            }
            FirebaseApp.configure(options: fileopts)
        }
    }

    static func forceReload() {
        FirebaseApp.configure()
    }

    public let firestore: Firestore = {
        checkInit()
        let settings: FirestoreSettings = {
            let s = FirestoreSettings()
            s.isPersistenceEnabled = false
            s.dispatchQueue = DispatchQueue.global()
            return s
        }()

        let db = Firestore.firestore()
        db.settings = settings

        return db
    }()

    public let functions: Functions = {
        checkInit()
        return Functions.functions(region: "asia-northeast1")
    }()
}
