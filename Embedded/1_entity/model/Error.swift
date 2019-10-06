//
//  Error.swift
//  Twibu
//
//  Created by abeyuya on 2019/06/22.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import Foundation

public enum TwibuError: Error, Equatable {
    case unknown(String?)
    case needFirebaseAuth(String?)
    case needTwitterAuth(String?)
    case signOut(String?)
    case twitterLogin(String?)
    case twitterLoginAlreadyExist(String?)
    case twitterRateLimit(String?)
    case firestoreError(String?)
    case firebaseFunctionsError(String?)
    case webArchiveError(String?)
    case apiError(String?)

    public static let alreadyExistTwitterAccountErrorCode = 17025
    private static let twitterApiRateLimitErrorMessage = "Rate limit exceeded"

    public static func isTwitterRateLimit(error: Error) -> Bool {
        guard let data = error.localizedDescription.data(using: .utf8) else { return false }

        guard let dict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            return false
        }

        guard let mes = dict["message"] as? String else { return false }

        if mes == twitterApiRateLimitErrorMessage {
            return true
        }

        return false
    }

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
        case .twitterLoginAlreadyExist(_): return "Twitterログインに失敗しました"
        case .twitterRateLimit(_): return "Twitter APIの利用頻度制限エラーが発生しました"
        case .firestoreError(_): return "通信に失敗しました"
        case .firebaseFunctionsError(_): return "通信に失敗しました"
        case .webArchiveError(_): return "予期せぬエラーが発生しました"
        case .apiError(_): return "通信に失敗しました"
        }
    }

    private var debugMessage: String? {
        switch self {
        case .unknown(let message): return message
        case .needFirebaseAuth(let message): return message
        case .needTwitterAuth(let message): return message
        case .signOut(let message): return message
        case .twitterLogin(let message): return message
        case .twitterLoginAlreadyExist(let message): return message
        case .twitterRateLimit(let message): return message
        case .firestoreError(let message): return message
        case .firebaseFunctionsError(let message): return message
        case .webArchiveError(let message): return message
        case .apiError(let message): return message
        }
    }
}
