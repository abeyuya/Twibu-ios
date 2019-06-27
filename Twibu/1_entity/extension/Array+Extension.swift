//
//  Array+Extension.swift
//  Twibu
//
//  Created by abeyuya on 2019/06/23.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import Foundation

extension Array {
//    func uniqyeBy(includeElement: @escaping (Element, Element) -> Bool) -> [Element] {
//        var results = [Element]()
//
//        forEach { (element) in
//            let existingElements = results.filter {
//                return includeElement(element, $0)
//            }
//            if existingElements.count == 0 {
//                results.append(element)
//            }
//        }
//
//        return results
//    }

    func unique<T: Hashable>(by: ((Element) -> (T))) -> [Element] {
        var set = Set<T>() //the unique list kept in a Set for fast retrieval
        var arrayOrdered = [Element]() //keeping the unique list of elements but ordered
        for value in self {
            if !set.contains(by(value)) {
                set.insert(by(value))
                arrayOrdered.append(value)
            }
        }

        return arrayOrdered
    }

    func intersect<T: Equatable>(obj: [T]) -> [T] {
        var ret = [T]()

        for x in self {
            if obj.contains(x as! T) {
                ret.append(x as! T)
            }
        }
        return ret
    }
}

extension Sequence where Element: Equatable {
    var unique: [Element] {
        return self.reduce(into: []) {
            uniqueElements, element in

            if !uniqueElements.contains(element) {
                uniqueElements.append(element)
            }
        }
    }
}
