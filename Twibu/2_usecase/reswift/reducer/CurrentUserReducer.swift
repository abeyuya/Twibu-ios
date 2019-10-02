//
//  CurrentUserReducer.swift
//  Twibu
//
//  Created by abeyuya on 2019/10/02.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import ReSwift
import FirebaseAuth
import Embedded

enum CurrentUserReducer {
    typealias State = TwibuUser

    enum Actions {
        struct Update: Action {
            let newUser: User
        }
    }

    static func reducer(action: Action, state: State?) -> State {
        var state = state ?? State(firebaseAuthUser: nil)

        switch action {
        case let a as Actions.Update:
            let newUser = TwibuUser(firebaseAuthUser: a.newUser)
            state = newUser

        default:
            break
        }

        return state
    }
}
