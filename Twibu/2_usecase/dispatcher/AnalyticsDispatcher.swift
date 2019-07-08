//
//  AnalyticsDispatcher.swift
//  Twibu
//
//  Created by abeyuya on 2019/07/09.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import Foundation
import FirebaseAnalytics

struct AnalyticsDispatcer {
    enum Event: String {
        case loginTry = "login_try"
        case login = "login"
        case logoutTry = "logout_try"
        case logout = "logout"
        case categoryRefresh = "category_refresh"
        case categoryLoad = "category_load"
        case bookmarkTap = "bookmark_tap"
        case share = "share"
        case commentShow = "comment_show"
        case commentHide = "comment_hide"
        case commentRefresh = "comment_refresh"
        case commentTap = "comment_tap"
        case commentShowTab = "comment_show_tab"
        case showMoreTwitterTap = "show_more_twitter_tap"
    }

    static func logging(_ event: Event, param: [String: Any]?) {
        Analytics.logEvent(
            event.rawValue,
            parameters: param
        )
    }
}
