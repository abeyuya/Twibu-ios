//
//  Firebase.swift
//  Twibu
//
//  Created by abeyuya on 2019/06/27.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import Foundation
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
            FirebaseApp.configure()
        }
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
