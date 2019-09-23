//
//  CommentRepository.swift
//  Embedded
//
//  Created by abeyuya on 2019/09/23.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import Foundation

public protocol CommentRepository {
    associatedtype Info: RepositoryPagingInfo

    static func fetchBookmarkComment(
        bookmarkUid: String,
        type: Repository<Info>.FetchType,
        completion: @escaping ((Repository<Info>.Response<[Comment]>) -> Void)
    )
}
