//
//  Category.swift
//  Twibu
//
//  Created by abeyuya on 2019/06/22.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import Foundation

public enum Category: String, Codable {
    case unknown = "unknown"
    case timeline = "timeline"
    case memo = "memo"
    case history = "history"

    case all = "all"
    case social = "social"
    case economics = "economics"
    case life = "life"
    case knowledge = "knowledge"
    case it = "it"
    case fun = "fun"
    case entertainment = "entertainment"
    case game = "game"

    public var displayString: String {
        switch self {
        case .unknown: return "カテゴリなし"
        case .timeline: return "タイムライン"
        case .memo: return "メモ"
        case .history: return "履歴"

        case .all: return "トップ"
        case .social: return "社会"
        case .economics: return "政治・経済"
        case .life: return "ライフスタイル"
        case .knowledge: return "ふむふむ"
        case .it: return "テクノロジー"
        case .fun: return "いろいろ"
        case .entertainment: return "芸能・スポーツ"
        case .game: return "アニメ・ゲーム"
        }
    }
}
