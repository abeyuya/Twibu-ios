//
//  TwibuFirebaseRecord.swift
//  Twibu
//
//  Created by abeyuya on 2019/06/23.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import Foundation

protocol TwibuFirestoreRecord {
    var uid: String { get }
}

extension TwibuFirestoreRecord {
    // 古いものを新しいもので置き換えつつ合体する
    static func merge<T: TwibuFirestoreRecord>(base: [T], add: [T]) -> [T] {
        var result = base

        add.forEach { b in
            if let i = result.firstIndex(where: { $0.uid == b.uid }) {
                result[i] = b
                return
            }
            result.append(b)
        }

        return result
    }
}
