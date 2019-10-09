//
//  CommentTableViewCell.swift
//  Twibu
//
//  Created by abeyuya on 2019/06/20.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import UIKit
import SwiftIcons
import Kingfisher

private let iconProcessor = DownsamplingImageProcessor(size: .init(width: 36 * 3, height: 36 * 3))

final class CommentTableViewCell: UITableViewCell {
    @IBOutlet private weak var commentContentView: CommentContentView!

    func set(bookmark: Bookmark?, comment: Comment) {
        commentContentView.set(bookmark: bookmark, comment: comment)
    }
}
