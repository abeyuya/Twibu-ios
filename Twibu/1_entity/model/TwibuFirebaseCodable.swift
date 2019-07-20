//
//  TwibuFirebaseRecord.swift
//  Twibu
//
//  Created by abeyuya on 2019/06/23.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import Foundation
import FirebaseFirestore

protocol TwibuFirestoreCodable: Codable {}

extension TwibuFirestoreCodable {
    init?(dictionary: [String: Any]) {
        let dict: [String: Any] = {
            var newDict = dictionary

            if let createdAt = dictionary["created_at"] as? Timestamp {
                newDict["created_at"] = createdAt.seconds
            } else {
                newDict.removeValue(forKey: "created_at")
            }

            if let updatedAt = dictionary["updated_at"] as? Timestamp {
                newDict["updated_at"] = updatedAt.seconds
            } else {
                newDict.removeValue(forKey: "updated_at")
            }
            return newDict
        }()

        do {
            self = try JSONDecoder().decode(
                Self.self,
                from: JSONSerialization.data(withJSONObject: dict)
            )
        } catch {
            Logger.print("\(Self.self)のdecodeに失敗しました dict: \(dict)")
            return nil
        }
    }
}
