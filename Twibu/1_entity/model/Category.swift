//
//  Category.swift
//  Twibu
//
//  Created by abeyuya on 2019/06/22.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import Foundation

enum Category: String, CaseIterable {
    case timeline = "timeline"
    case all = "all"
    case social = "social"
    case economics = "economics"
    case life = "life"
    case knowledge = "knowledge"
    case it = "it"
    case fun = "fun"
    case entertainment = "entertainment"
    case game = "game"

    var displayString: String {
        switch self {
        case .timeline: return "タイムライン"
        case .all: return "総合"
        case .social: return "世の中"
        case .economics: return "政治と経済"
        case .life: return "暮らし"
        case .knowledge: return "学び"
        case .it: return "テクノロジー"
        case .fun: return "おもしろ"
        case .entertainment: return "エンタメ"
        case .game: return "アニメとゲーム"
        }
    }

    var index: Int {
        return Category.allCases.firstIndex(of: self)!
    }

    init?(index: Int) {
        self = Category.allCases[index]
    }

    static func calcLogicalIndex(physicalIndex: Int) -> Int {
        let i = physicalIndex % Category.allCases.count

        if i >= 0 {
            return i
        }

        return i + Category.allCases.count
    }
}
