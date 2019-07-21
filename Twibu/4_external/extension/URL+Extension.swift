//
//  URL+Extension.swift
//  Twibu
//
//  Created by abeyuya on 2019/07/21.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import Foundation

extension URL {
    func queryParams() -> [String : String] {
        var params = [String : String]()

        guard let comps = URLComponents(string: self.absoluteString) else {
            return params
        }
        guard let queryItems = comps.queryItems else { return params }

        for queryItem in queryItems {
            params[queryItem.name] = queryItem.value
        }
        return params
    }
}
