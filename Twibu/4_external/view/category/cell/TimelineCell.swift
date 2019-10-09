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
    @IBOutlet private weak var categoryContentView: CategoryContentView!
    @IBOutlet private weak var userArea: UIView!
    @IBOutlet private weak var iconImageView: UIImageView! {
        didSet {
            iconImageView.clipsToBounds = true
            iconImageView.layer.cornerRadius = iconImageView.frame.size.width / 2
        }
    }
    @IBOutlet private weak var displayNameLabel: UILabel!
    @IBOutlet private weak var verifiedLabel: UILabel!
    @IBOutlet private weak var usernameLabel: UILabel!
    @IBOutlet private weak var commentLabel: UILabel!

    public func set(bookmark: Bookmark, alreadyRead: Bool, showImage: Bool) {
        categoryContentView.set(bookmark: bookmark, alreadyRead: alreadyRead, showImage: showImage)
    }

    func set(saveState: CategoryContentView.SaveState) {
        categoryContentView.set(saveState: saveState)
    }

    public func set(comment: Comment) {
        let c = comment
        iconImageView.image = nil
        if let url = URL(string: c.user.profile_image_url) {
            iconImageView.kf.setImage(with: url, options: [.processor(iconProcessor)])
        }

        displayNameLabel.text = c.user.name
        usernameLabel.text = "@" + c.user.screen_name

        verifiedLabel.isHidden = true
        if c.user.verified == true {
            verifiedLabel.setIcon(
                icon: .fontAwesomeSolid(.checkCircle),
                iconSize: 13,
                color: .twitter
            )
            verifiedLabel.isHidden = false
        }

        commentLabel.isHidden = true
        if let hasComment = c.has_comment, hasComment {
            commentLabel.isHidden = false
            commentLabel.text = c.text
        }
    }
}
