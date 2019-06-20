//
//  TimelineCell.swift
//  Twibu
//
//  Created by abeyuya on 2019/06/16.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import UIKit

class TimelineCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var usersCountLabel: UILabel!
    @IBOutlet weak var domainLabel: UILabel!
    @IBOutlet weak var createdAtLabel: UILabel!
    @IBOutlet weak var thumbnailImageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func set(bookmark: Bookmark) {
        titleLabel.text = bookmark.title ?? "タイトルが取得できませんでした"

        if let count = bookmark.comment_count {
            usersCountLabel.text = "\(count) users"
        } else {
            usersCountLabel.isHidden = true
        }

        if let url = bookmark.url.expanded_url, let domain = URL(string: url)?.host {
            domainLabel.text = domain
        } else {
            domainLabel.isHidden = true
        }

        if let sec = bookmark.created_at {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd:MM"
            let date = Date(timeIntervalSince1970: TimeInterval(sec))
            createdAtLabel.text = formatter.string(from: date)
        } else {
            createdAtLabel.isHidden = true
        }

        if let imageUrl = bookmark.image_url {

        } else {
            // レイアウト変えたい
        }
    }

//    func parseTwitterDate(twitterDate: String, outputDateFormat: String) -> String? {
//        let formatter = DateFormatter()
//        formatter.dateFormat = "EEE MMM dd HH:mm:ss Z yyyy"
//
//        let indate = formatter.date(from: twitterDate)
//        let outputFormatter = DateFormatter()
//        outputFormatter.dateFormat = "hh:mm a dd:MM:yy"
//        var outputDate: String?
//        if let d = indate {
//            outputDate = outputFormatter.string(from: d)
//        }
//        return outputDate;
//    }
}
