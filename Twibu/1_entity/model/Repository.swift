//
//  Repository.swift
//  Twibu
//
//  Created by abeyuya on 2019/06/27.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import Foundation
import FirebaseFirestore

struct Repository {
    enum FetchType {
        case new, add
    }

    struct Response<T: TwibuFirestoreCodable> {
        let snapshot: DocumentSnapshot
        let obj: T

        init?(snapshot: DocumentSnapshot) {
            guard let d = snapshot.data(), let obj = T(dictionary: d) else { return nil }
            self.obj = obj
            self.snapshot = snapshot
        }

        static func merge(base: [Repository.Response<T>], add: [Repository.Response<T>]) -> [Repository.Response<T>] {
            var result = base

            add.forEach { b in
                if let i = result.firstIndex(where: { $0.snapshot.documentID == b.snapshot.documentID }) {
                    result[i] = b
                    return
                }
                result.append(b)
            }

            return result
        }
    }
}
