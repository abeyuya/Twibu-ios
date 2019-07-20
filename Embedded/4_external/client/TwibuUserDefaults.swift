//
//  TwibuUserDefaults.swift
//  Embedded
//
//  Created by abeyuya on 2019/07/20.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import Foundation

public final class TwibuUserDefaults {
    public static let shared = TwibuUserDefaults()
    private init() {}

    private let client = UserDefaults(suiteName: "group.com.github.abeyuya.Twibu")!

    private enum Key: String {
        case firebaseUid = "firebaseUid"
    }

    public func setFirebaseUid(uid: String) {
        client.set(uid, forKey: Key.firebaseUid.rawValue)
    }

    public func getFirebaseUid() -> String? {
        return client.string(forKey: Key.firebaseUid.rawValue)
    }
}
