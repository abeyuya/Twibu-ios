//
//  CommentRepository.swift
//  Embedded
//
//  Created by abeyuya on 2019/09/23.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import Foundation

public protocol CommentRepository {
    func fetchBookmarkComment(
        bookmarkUid: String,
        type: Repository.FetchType,
        completion: @escaping ((Repository.Response<[Comment]>) -> Void)
    )

    func execUpdateBookmarkComment(
        bookmarkUid: String,
        title: String,
        url: String,
        completion: @escaping (Result<[Comment]>) -> Void
    )
}
