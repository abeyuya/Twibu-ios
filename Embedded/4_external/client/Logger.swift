//
//  Logger.swift
//  Twibu
//
//  Created by abeyuya on 2019/07/12.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import Foundation

public struct Logger {
    public static func print(
        _ debug: Any = "",
        function: String = #function,
        file: String = #file,
        line: Int = #line
    ) {
        let filename: String = {
            if let last = file.split(separator: "/").last {
                return String(last)
            }
            return file
        }()

        Swift.print(
            "-----\n",
            "Logger:\(filename):L\(line):\(function) \(debug)",
            "\n\n"
        )
    }
}
