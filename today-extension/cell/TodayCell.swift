//
//  TodayCell.swift
//  today-extension
//
//  Created by abeyuya on 2019/07/20.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import UIKit
import Embedded
import Kingfisher

final class TodayCell: UITableViewCell {

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

    func set(bookmark: Bookmark, showImage: Bool) {
        titleLabel.text = bookmark.trimmedTitle ?? "タイトルが取得できませんでした"

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
        if showImage,
            let imageUrl = bookmark.image_url,
            imageUrl != "",
            let url = URL(string: imageUrl) {
            thumbnailImageView.isHidden = false
            thumbnailImageView.kf.setImage(with: url)
        } else {
            thumbnailImageView.isHidden = true
        }

        faviconImageView.image = nil
        faviconImageView.isHidden = true
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
                    case .failure(_):
                        // self.faviconImageView.isHidden = true
                        // print(error)
                        break
                    }
            })
        }
    }
}
