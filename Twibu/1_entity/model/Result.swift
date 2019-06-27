//
//  Result.swift
//  Twibu
//
//  Created by abeyuya on 2019/06/16.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import Foundation

enum Result<T> {
    case success(T)
    case failure(TwibuError)
}
