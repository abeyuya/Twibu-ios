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

        if u.providerData.isEmpty {
            return false
        }

        return true
    }
}
