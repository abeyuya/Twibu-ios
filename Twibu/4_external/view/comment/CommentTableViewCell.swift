//
//  CommentTableViewCell.swift
//  Twibu
//
//  Created by abeyuya on 2019/06/20.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import UIKit

class CommentTableViewCell: UITableViewCell {

    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var commentLabel: UILabel!
    @IBOutlet weak var displayNameLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var retweetCountLabel: UILabel!
    @IBOutlet weak var favoriteCountLabel: UILabel!
    @IBOutlet weak var tweetAtLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        profileImageView.clipsToBounds = true
        profileImageView.layer.cornerRadius = profileImageView.frame.size.width / 2
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    func set(bookmark: Bookmark?, comment: Comment) {
        if let t = bookmark?.trimmedTitle {
            commentLabel.text = comment.replacedText(title: t)
        } else {
            commentLabel.text = comment.text
        }

        profileImageView.image = nil
        if let url = URL(string: comment.user.profile_image_url) {
            profileImageView.kf.setImage(with: url)
        } else {
//            profileImageView.kf.setImage(with: url)
        }

        displayNameLabel.text = comment.user.name
        usernameLabel.text = "@" + comment.user.screen_name
        retweetCountLabel.text = "↩\(comment.retweet_count)"
        favoriteCountLabel.text = "♡\(comment.favorite_count)"
        tweetAtLabel.text = parseTwitterDate(twitterDate: comment.tweet_at)
    }

    private func parseTwitterDate(twitterDate: String) -> String? {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE MMM dd HH:mm:ss Z yyyy"

        let indate = formatter.date(from: twitterDate)
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "yyyy/MM/dd h:mm"
        var outputDate: String?
        if let d = indate {
            outputDate = outputFormatter.string(from: d)
        }
        return outputDate;
    }
}
