//
//  TwibuUser.swift
//  Twibu
//
//  Created by abeyuya on 2019/07/03.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import Foundation
import FirebaseAuth

struct TwibuUser {
    let firebaseAuthUser: User?

    var isTwitterLogin: Bool {
        guard let u = firebaseAuthUser else {
            return false
        }

        let twitterInfo = u.providerData.first { $0.providerID == "twitter.com" }
        if twitterInfo == nil {
            return false
        }

        return true
    }

    var isAdmin: Bool {
        guard let u = firebaseAuthUser else {
            return false
        }

        let twitterInfo = u.providerData.first { $0.providerID == "twitter.com" }
        guard let i = twitterInfo else { return false }

        return i.uid == "225056817" // abe_abe_yuya
    }
}
