//
//  Env.swift
//  Twibu
//
//  Created by abeyuya on 2019/06/22.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import Foundation

public enum Env {
    case debug, release

    public static var current: Env {
        #if DEBUG
        return .debug
        #else
        return .release
        #endif
    }
}
