//
//  Env.swift
//  Twibu
//
//  Created by abeyuya on 2019/06/22.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import Foundation

public enum Env {
    case debug, release, adhoc

    public static var current: Env {
        #if DEBUG
        return .debug
        #elseif ADHOC
        return .adhoc
        #else
        return .release
        #endif
    }
}
