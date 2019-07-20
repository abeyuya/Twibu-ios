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
    static func log(
        _ error: TwibuError,
        function: String = #function,
        file: String = #file,
        line: Int = #line
    ) {
        Swift.print("error: \(error.displayMessage)")
        Crashlytics.sharedInstance().recordError(error)
    }

    static func print(
        _ debug: Any = "",
        function: String = #function,
        file: String = #file,
        line: Int = #line
    ) {
        var filename = file
        if let match = filename.range(of: "[^/]*$", options: .regularExpression) {
            filename = String(filename[match.upperBound...])
        }
        Swift.print(
            "-----\n",
            "Logger:\(filename):L\(line):\(function) \(debug)",
            "\n\n"
        )
    }
}
