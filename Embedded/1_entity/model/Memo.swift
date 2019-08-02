//
//  Memo.swift
//  Embedded
//
//  Created by abeyuya on 2019/08/02.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import Foundation
import FirebaseFirestore

public struct Memo {
    public let bookmark_ref: DocumentReference
    public let memo: String
    public let updated_at: Int

    init?(dictionary: [String: Any]) {
        guard let ref = dictionary["bookmark_ref"] as? DocumentReference else { return nil }
        self.bookmark_ref = ref

        guard let memo = dictionary["memo"] as? String else { return nil }
        self.memo = memo

        guard let updatedAt = dictionary["updated_at"] as? Timestamp else { return nil }
        self.updated_at = Int(updatedAt.seconds)
    }
}
