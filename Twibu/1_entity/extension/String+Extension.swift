//
//  String.swift
//  Twibu
//
//  Created by abeyuya on 2019/06/27.
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

    func pickupDeplicateString(target: String) -> String? {
        let textArr: [Character] = Array(self)
        let titleArr: [Character] = Array(target)

        var textStartIndex: Int?
        var textEndIndex: Int?

        for (i, textC) in textArr.enumerated() {
            guard textEndIndex == nil else { break }

            guard let tsi = textStartIndex else {
                if textC == target.first {
                    textStartIndex = i
                }
                continue
            }

            if (titleArr.endIndex) == (i - tsi) {
                textEndIndex = i
                break
            }

            if textC == titleArr[i - tsi] {
                continue
            } else {
                textEndIndex = i
                break
            }
        }

        guard let si = textStartIndex, let ei = textEndIndex else { return nil }
        let duplicateArr = textArr[si..<ei]
        return String(duplicateArr)
    }
}

extension String {
    init?(htmlEncodedString: String) {
        guard let data = htmlEncodedString.data(using: .utf8) else {
            return nil
        }
        
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        
        guard let attributedString = try? NSAttributedString(
            data: data,
            options: options,
            documentAttributes: nil) else { return nil }
        
        self.init(attributedString.string)
    }

    func manualHtmlDecode() -> String {
        return self
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&amp;", with: "&")
    }
}
