//
//  TimelineCell.swift
//  Twibu
//
//  Created by abeyuya on 2019/06/16.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import UIKit
import Kingfisher

class TimelineCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var usersCountLabel: UILabel!
    @IBOutlet weak var domainLabel: UILabel!
    @IBOutlet weak var createdAtLabel: UILabel!
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var faviconImageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()

        thumbnailImageView.layer.cornerRadius = 4
        thumbnailImageView.clipsToBounds = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func set(bookmark: Bookmark) {
        titleLabel.text = bookmark.title ?? "タイトルが取得できませんでした"

        if let count = bookmark.comment_count, count > 0 {
            usersCountLabel.isHidden = false
            usersCountLabel.text = "\(count) tweets"
        } else {
            usersCountLabel.isHidden = true
        }

        if let domain = URL(string: bookmark.url)?.host {
            domainLabel.isHidden = false
            domainLabel.text = domain
        } else {
            domainLabel.isHidden = true
        }

        if let sec = bookmark.created_at {
            createdAtLabel.isHidden = false
            let formatter = DateFormatter()
            formatter.dateFormat = "M/d"
            let date = Date(timeIntervalSince1970: TimeInterval(sec))
            createdAtLabel.text = formatter.string(from: date)
        } else {
            createdAtLabel.isHidden = true
        }

        thumbnailImageView.image = nil
        if let imageUrl = bookmark.image_url, let url = URL(string: imageUrl) {
            thumbnailImageView.kf.setImage(with: url)
        } else {
            // レイアウト変えたい
        }

        faviconImageView.image = nil
        if let url = URL(string: bookmark.url),
            let scheme = url.scheme,
            let host = url.host,
            let favicionUrl = URL(string: "\(scheme)://\(host)/favicon.ico") {
            faviconImageView.kf.setImage(
                with: favicionUrl,
                placeholder: nil,
                options: nil,
                progressBlock: nil,
                completionHandler: { result in
                    switch result {
                    case .success(let res):
                        self.faviconImageView.isHidden = false
                        self.faviconImageView.image = res.image
                    case .failure(let error):
                        self.faviconImageView.isHidden = true
                        // print(error)
                    }
            })
        }
    }
}
