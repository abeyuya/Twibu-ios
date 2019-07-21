//
//  Encodable+Extension.swift
//  Embedded
//
//  Created by abeyuya on 2019/07/21.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import Foundation

public extension Encodable {
    var dictionary: [String: Any]? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data, options: .allowFragments)).flatMap { $0 as? [String: Any] }
    }
}
