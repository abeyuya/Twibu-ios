//
//  Logger.swift
//  Twibu
//
//  Created by abeyuya on 2019/07/12.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import Foundation
import Crashlytics

struct Logger {
    static func log(_ error: TwibuError) {
        print("error: \(error.displayMessage)")
        Crashlytics.sharedInstance().recordError(error)
    }
}
