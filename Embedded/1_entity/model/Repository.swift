//
//  Repository.swift
//  Twibu
//
//  Created by abeyuya on 2019/06/27.
//  Copyright © 2019 abeyuya. All rights reserved.
//

// NOTE: firestoreの依存性を持ち込まないためにAnyにしているけど、どうにかしたい
public struct RepositoryPagingInfo: Equatable {
    public var lastSnapshot: NSObject?
    public init(lastSnapshot: NSObject?) {
        self.lastSnapshot = lastSnapshot
    }
}

public enum Repository {
    public enum FetchType {
        case new(limit: Int)
        case add(limit: Int, pagingInfo: RepositoryPagingInfo?)

        public var debugName: String {
            switch self {
            case .new: return "new"
            case .add(_): return "add"
            }
        }
    }

    public struct Result<T: Equatable>: Equatable {
        public let item: T
        public let pagingInfo: RepositoryPagingInfo?
        public let hasMore: Bool

        public init(item: T, pagingInfo: RepositoryPagingInfo?, hasMore: Bool) {
            self.item = item
            self.pagingInfo = pagingInfo
            self.hasMore = hasMore
        }
    }

    public enum ResponseState: Equatable {
        case notYetLoading
        case loading
        case additionalLoading
        case success
        case failure(TwibuError)
    }
}
