//
//  Firebase.swift
//  Twibu
//
//  Created by abeyuya on 2019/06/27.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import Foundation
import FirebaseFirestore
import FirebaseFunctions

public final class TwibuFirebase {
    private init() {}

    public static let firestore: Firestore = {
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        settings.dispatchQueue = DispatchQueue.global()

        let db = Firestore.firestore()
        db.settings = settings

        return db
    }()

    public static let functions: Functions = {
        return Functions.functions(region: "asia-northeast1")
    }()
}
