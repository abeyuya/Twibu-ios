//
//  Dictionary+Extension.swift
//  Embedded
//
//  Created by abeyuya on 2019/07/21.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import Foundation

public extension Dictionary {
    var queryString: String {
        var output: String = ""
        for (key,value) in self {
            output +=  "\(key)=\(value)&"
        }
        output = String(output.dropLast())
        return output
    }
}
