//
//  Timeline.swift
//  Twibu
//
//  Created by abeyuya on 2019/07/12.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import FirebaseFirestore

struct Timeline {
    let bookmark_ref: DocumentReference
    let post_at: Int
    let updated_at: Int

    init?(dictionary: [String: Any]) {
        guard let ref = dictionary["bookmark_ref"] as? DocumentReference else { return nil }
        self.bookmark_ref = ref

        guard let postAt = dictionary["post_at"] as? Int else { return nil }
        self.post_at = postAt

        guard let updatedAt = dictionary["updated_at"] as? Timestamp else { return nil }
        self.updated_at = Int(updatedAt.seconds)
    }
}
