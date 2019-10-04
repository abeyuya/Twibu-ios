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

    public func set(bookmark: Bookmark, alreadyRead: Bool, showImage: Bool) {
        categoryContentView.set(bookmark: bookmark, alreadyRead: alreadyRead, showImage: showImage)
    }

    func set(saveState: CategoryContentView.SaveState) {
        categoryContentView.set(saveState: saveState)
    }

    public func set(userInfo: Comment.User?) {
        userArea.isHidden = true
        guard let u = userInfo else { return }

        userArea.isHidden = false
        iconImageView.image = nil
        if let url = URL(string: u.profile_image_url) {
            let processor = ResizingImageProcessor(
                referenceSize: .init(width: 96, height: 96),
                mode: .aspectFit
            )
            iconImageView.kf.setImage(with: url, options: [.processor(processor)])
        }

        displayNameLabel.text = u.screen_name
        usernameLabel.text = u.twitter_user_id

        verifiedLabel.isHidden = true
        if u.verified == true {
            verifiedLabel.setIcon(
                icon: .fontAwesomeSolid(.checkCircle),
                iconSize: 13,
                color: .twitter
            )
            verifiedLabel.isHidden = false
        }
    }
}
