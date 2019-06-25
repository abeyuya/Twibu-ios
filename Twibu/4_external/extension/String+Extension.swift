//
//  String+Extension.swift
//  Twibu
//
//  Created by abeyuya on 2019/06/26.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import Foundation

extension String {
    // https://qiita.com/kawanamiyuu/items/57ccec09c2f6cbc5b175
    func capture(pattern: String, group: [Int]) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return []
        }

        guard let matched = regex.firstMatch(in: self, range: NSRange(location: 0, length: self.count)) else {
            return []
        }

        return group.map { group -> String in
            return (self as NSString).substring(with: matched.range(at: group))
        }
    }
}
