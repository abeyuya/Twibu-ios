//
//  TimelineCell.swift
//  Twibu
//
//  Created by abeyuya on 2019/10/04.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import UIKit
import Embedded
import Kingfisher

private let iconProcessor = DownsamplingImageProcessor(size: .init(width: 96, height: 96))

final class TimelineCell: UITableViewCell, ArticleCellProtocol {
    @IBOutlet private weak var commentContentView: CommentContentView!
    @IBOutlet private weak var categoryContentView: CategoryContentView!
    @IBOutlet private weak var articleWrapperView: UIView! {
        didSet {
            articleWrapperView.layer.cornerRadius = 12
            articleWrapperView.layer.borderWidth = 1
            articleWrapperView.layer.borderColor = UIColor.originTertiaryLabel.cgColor
        }
    }

    func set(bookmark: Bookmark, alreadyRead: Bool, showImage: Bool) {
        categoryContentView.set(bookmark: bookmark, alreadyRead: alreadyRead, showImage: showImage)
    }

    func set(saveState: CategoryContentView.SaveState) {
        categoryContentView.set(saveState: saveState)
    }

    func set(bookmark: Bookmark, comment: Comment) {
        commentContentView.set(bookmark: bookmark, comment: comment)
    }
}
