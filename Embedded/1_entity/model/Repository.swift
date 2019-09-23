//
//  Repository.swift
//  Twibu
//
//  Created by abeyuya on 2019/06/27.
//  Copyright © 2019 abeyuya. All rights reserved.
//

public protocol RepositoryPagingInfo {}

public struct Repository<P: RepositoryPagingInfo> {
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

    public struct Result<T> {
        public let item: T
        public let pagingInfo: P?
        public let hasMore: Bool

        public init(item: T, pagingInfo: P?, hasMore: Bool) {
            self.item = item
            self.pagingInfo = pagingInfo
            self.hasMore = hasMore
        }
    }

    public enum Response<T> {
        case notYetLoading
        case loading(Result<T>)
        case success(Result<T>)
        case failure(TwibuError)

        public var item: T? {
            switch self {
            case .success(let result): return result.item
            case .loading(let result): return result.item
            case .failure(_): return nil
            case .notYetLoading: return nil
            }
        }
    }
}
