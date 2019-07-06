//
//  CommentTableViewCell.swift
//  Twibu
//
//  Created by abeyuya on 2019/06/20.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import UIKit
import SwiftIcons

final class CommentTableViewCell: UITableViewCell {

    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var commentLabel: UILabel!
    @IBOutlet weak var displayNameLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var retweetCountLabel: UILabel!
    @IBOutlet weak var favoriteCountLabel: UILabel!
    @IBOutlet weak var tweetAtLabel: UILabel!
    @IBOutlet weak var verifiedLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        profileImageView.clipsToBounds = true
        profileImageView.layer.cornerRadius = profileImageView.frame.size.width / 2
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    func set(bookmark: Bookmark?, comment: Comment) {
        if let p = comment.parsed_comment {
            commentLabel.attributedText = buildAttr(parsedText: p)
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
        verifiedLabel.isHidden = true
        if comment.user.verified == true {
            verifiedLabel.setIcon(
                icon: .fontAwesomeSolid(.checkCircle),
                iconSize: 13,
                color: .twitter
            )
            verifiedLabel.isHidden = false
        }
        usernameLabel.text = "@" + comment.user.screen_name
        retweetCountLabel.setIcon(
            prefixText: "",
            icon: .fontAwesomeSolid(.retweet),
            iconColor: .darkGray,
            postfixText: "  \(comment.retweet_count)",
            postfixTextColor: .darkGray,
            size: nil
        )
        favoriteCountLabel.setIcon(
            prefixText: "",
            icon: .fontAwesomeRegular(.heart),
            iconColor: .darkGray,
            postfixText: "  \(comment.favorite_count)",
            postfixTextColor: .darkGray,
            size: nil
        )
        tweetAtLabel.text = parseTwitterDate(twitterDate: comment.tweet_at)
    }

    private func parseTwitterDate(twitterDate: String) -> String? {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE MMM dd HH:mm:ss Z yyyy"

        let indate = formatter.date(from: twitterDate)
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "yyyy/MM/dd H:mm"
        var outputDate: String?
        if let d = indate {
            outputDate = outputFormatter.string(from: d)
        }
        return outputDate;
    }

    private func buildAttr(parsedText: [Comment.TextBlock]) -> NSAttributedString {
        let arr = NSMutableAttributedString()

        parsedText.forEach { t in
            switch t.type {
            case .comment, .unknown:
                arr.append(buildNormalAttrStr(str: t.text))
            case .title:
                arr.append(buildTitleAttrStr(str: t.text))
            case .space:
                arr.append(buildNormalAttrStr(str: t.text))
            case .url:
                arr.append(buildUrlAttrStr(str: t.text))
            case .hashtag:
                arr.append(buildHashtagAttrStr(str: t.text))
            case .via:
                arr.append(buildHashtagAttrStr(str: t.text))
            case .error:
                arr.append(buildNormalAttrStr(str: t.text))
            }
        }

        return arr
    }

    private func buildNormalAttrStr(str: String) -> NSAttributedString {
        let att: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: UIColor.darkText
        ]
        return NSAttributedString(
            string: str.manualHtmlDecode(),
            attributes: att
        )
    }

    private func buildTitleAttrStr(str: String) -> NSAttributedString {
        let att: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor.darkGray
        ]
        return NSAttributedString(string: "<title>", attributes: att)
    }

    private func buildUrlAttrStr(str: String) -> NSAttributedString {
        let att: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor.darkGray
        ]
        return NSAttributedString(string: "<url>", attributes: att)
    }

    private func buildHashtagAttrStr(str: String) -> NSAttributedString {
        let att: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor.darkGray
        ]
        return NSAttributedString(string: str, attributes: att)
    }
}
