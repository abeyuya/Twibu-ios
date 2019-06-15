//
//  Device.swift
//  Twibu
//
//  Created by abeyuya on 2019/06/15.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import Foundation

enum DeviceType {
    case simulator, real

    static var current: DeviceType {
        #if targetEnvironment(simulator)
        return .simulator
        #else
        return .real
        #endif
    }
}
