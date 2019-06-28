//
//  Response.swift
//  Twibu
//
//  Created by abeyuya on 2019/06/23.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import Foundation

enum ResponseState<T> {
    case notYetLoading
    case loading(T)
    case success(T)
    case faillure(TwibuError)

    var item: T? {
        switch self {
        case .notYetLoading: return nil
        case .loading(let i): return i
        case .success(let i): return i
        case .faillure(_): return nil
        }
    }
}
