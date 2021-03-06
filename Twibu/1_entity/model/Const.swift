//
//  Const.swift
//  Twibu
//
//  Created by abeyuya on 2019/06/22.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import Foundation
import UIKit

struct Const {
    static let twitterConsumerKey: String = {
        return "6TWMRUdUTZytnBMrtO9WqTuxu"
    }()

    static let twitterConsumerSecret: String = {
        return "VnFMSY5A3HolXfCtRlR2VyvBGp95LSazKKpDYAsKBPt0J3NacG"
    }()

    static let twitterCallbackUrlProtocol: String = {
        return "twitterkit-6twmrudutzytnbmrto9wqtuxu"
    }()

    static let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
    static let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""
}
