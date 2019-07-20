//
//  Error.swift
//  Twibu
//
//  Created by abeyuya on 2019/06/22.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import Foundation

public enum TwibuError: Error {
    case unknown(String?)
    case needFirebaseAuth(String?)
    case needTwitterAuth(String?)
    case signOut(String?)
    case twitterLogin(String?)
    case firestoreError(String?)
    case firebaseFunctionsError(String?)

    public var displayMessage: String {
        if Env.current == .debug {
            return [
                userMessage,
                "--- show only debug ---",
                debugMessage ?? "no debug message",
                localizedDescription
            ].joined(separator: "\n")
        }

        return userMessage
    }

    private var userMessage: String {
        switch self {
        case .unknown(_): return "予期せぬエラーが発生しました"
        case .needFirebaseAuth(_): return "予期せぬエラーが発生しました"
        case .needTwitterAuth(_): return "Twitterでログインしてください"
        case .signOut(_): return "ログアウトに失敗しました"
        case .twitterLogin(_): return "Twitterログインに失敗しました"
        case .firestoreError(_): return "通信に失敗しました"
        case .firebaseFunctionsError(_): return "通信に失敗しました"
        }
    }

    private var debugMessage: String? {
        switch self {
        case .unknown(let message): return message
        case .needFirebaseAuth(let message): return message
        case .needTwitterAuth(let message): return message
        case .signOut(let message): return message
        case .twitterLogin(let message): return message
        case .firestoreError(let message): return message
        case .firebaseFunctionsError(let message): return message
        }
    }
}
