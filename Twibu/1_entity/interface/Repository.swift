//
//  Repository.swift
//  Twibu
//
//  Created by abeyuya on 2019/06/27.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import Foundation
import FirebaseFirestore

struct Repository {
    enum FetchType {
        case new, add(DocumentSnapshot?)
    }

    struct Result<T> {
        let item: T
        let lastSnapshot: DocumentSnapshot?
        let hasMore: Bool
    }

    enum Response<T> {
        case notYetLoading
        case loading(Result<T>)
        case success(Result<T>)
        case failure(TwibuError)

        var item: T? {
            switch self {
            case .success(let result): return result.item
            case .loading(let result): return result.item
            case .failure(_): return nil
            case .notYetLoading: return nil
            }
        }
    }
}
