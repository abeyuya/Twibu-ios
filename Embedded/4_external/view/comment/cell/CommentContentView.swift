//
//  CommentContentView.swift
//  Embedded
//
//  Created by abeyuya on 2019/10/09.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import UIKit
import SwiftIcons
import Kingfisher

private let iconProcessor = DownsamplingImageProcessor(size: .init(width: 36 * 3, height: 36 * 3))

public final class CommentContentView: UIView {
    @IBOutlet private weak var profileImageView: UIImageView! {
        didSet {
            profileImageView.clipsToBounds = true
            profileImageView.layer.cornerRadius = profileImageView.frame.size.width / 2
        }
    }
    @IBOutlet private weak var commentLabel: UILabel!
    @IBOutlet private weak var displayNameLabel: UILabel!
    @IBOutlet private weak var usernameLabel: UILabel!
    @IBOutlet private weak var retweetCountLabel: UILabel!
    @IBOutlet private weak var favoriteCountLabel: UILabel!
    @IBOutlet private weak var tweetAtLabel: UILabel!
    @IBOutlet private weak var verifiedLabel: UILabel!

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    private func commonInit() {
        translatesAutoresizingMaskIntoConstraints = false
        guard let v = UINib(nibName: "\(Self.self)", bundle: Bundle(for: Self.self))
            .instantiate(withOwner: self, options: nil)
            .first as? UIView else { return }

        v.translatesAutoresizingMaskIntoConstraints = false
        addSubview(v)
        NSLayoutConstraint.activate([
            v.topAnchor.constraint(equalTo: topAnchor),
            v.leftAnchor.constraint(equalTo: leftAnchor),
            v.rightAnchor.constraint(equalTo: rightAnchor),
            v.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    public func set(bookmark: Bookmark?, comment: Comment) {
        if let p = comment.parsed_comment {
            commentLabel.attributedText = buildAttr(parsedText: p)
        } else {
            commentLabel.text = comment.text
        }

        profileImageView.image = nil
        if let url = URL(string: comment.user.profile_image_url) {
            profileImageView.kf.setImage(with: url, options: [.processor(iconProcessor)])
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
            iconColor: .originSecondaryLabel,
            postfixText: "  \(comment.retweet_count)",
            postfixTextColor: .originSecondaryLabel,
            size: nil
        )
        favoriteCountLabel.setIcon(
            prefixText: "",
            icon: .fontAwesomeRegular(.heart),
            iconColor: .originSecondaryLabel,
            postfixText: "  \(comment.favorite_count)",
            postfixTextColor: .originSecondaryLabel,
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
            case .ignore_symbol:
                arr.append(buildHashtagAttrStr(str: t.text))
            case .reply:
                arr.append(buildHashtagAttrStr(str: t.text))
            case .system_post:
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
            .foregroundColor: UIColor.originLabel
        ]
        return NSAttributedString(
            string: str.manualHtmlDecode(),
            attributes: att
        )
    }

    private func buildTitleAttrStr(str: String) -> NSAttributedString {
        let att: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor.originSecondaryLabel
        ]
        return NSAttributedString(string: "<title>", attributes: att)
    }

    private func buildUrlAttrStr(str: String) -> NSAttributedString {
        let att: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor.originSecondaryLabel
        ]
        return NSAttributedString(string: "<url>", attributes: att)
    }

    private func buildHashtagAttrStr(str: String) -> NSAttributedString {
        let att: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor.originSecondaryLabel
        ]
        return NSAttributedString(string: str, attributes: att)
    }
}
