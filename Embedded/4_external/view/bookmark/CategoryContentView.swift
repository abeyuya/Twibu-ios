//
//  BookmarkCell.swift
//  Twibu
//
//  Created by abeyuya on 2019/06/16.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import UIKit
import Kingfisher

private let thumbProcessor = ResizingImageProcessor(
    referenceSize: .init(width: 210, height: 210),
    mode: .aspectFit
)
private let faviProcessor = DownsamplingImageProcessor(size: .init(width: 16 * 3, height: 16 * 3))

final public class CategoryContentView: UIView {
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var usersCountLabel: UILabel!
    @IBOutlet private weak var domainLabel: UILabel!
    @IBOutlet private weak var createdAtLabel: UILabel!
    @IBOutlet private weak var thumbnailImageView: UIImageView! {
        didSet {
            thumbnailImageView.layer.cornerRadius = 4
            thumbnailImageView.clipsToBounds = true
        }
    }
    @IBOutlet private weak var faviconImageView: UIImageView!
    @IBOutlet private weak var saveStateLabel: UILabel!
    @IBOutlet private weak var thumbnailWidthConstraint: NSLayoutConstraint!

    public enum SaveState {
        case none, saving(Double), saved
    }

    private var saveState: SaveState = .none

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

    public func set(bookmark: Bookmark, alreadyRead: Bool, showImage: Bool) {
        titleLabel.text = bookmark.trimmedTitle ?? "タイトルが取得できませんでした"
        if alreadyRead {
            titleLabel.textColor = .originSecondaryLabel
        } else {
            titleLabel.textColor = .originLabel
        }

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
        if showImage {
            thumbnailWidthConstraint.constant = 70
            if let imageUrl = bookmark.image_url, !imageUrl.isEmpty, let url = URL(string: imageUrl) {
                thumbnailImageView.kf.setImage(with: url, options: [.processor(thumbProcessor)])
                thumbnailImageView.isHidden = false
            } else {
            }
        } else {
            thumbnailWidthConstraint.constant = 0
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
                options: [.processor(faviProcessor)],
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

        updateSaveStateLabel()
    }

    public func set(saveState: SaveState) {
        self.saveState = saveState
        updateSaveStateLabel()
    }

    private func updateSaveStateLabel() {
        switch saveState {
        case .none:
            saveStateLabel.isHidden = true
        case .saving(let progress):
            saveStateLabel.isHidden = false
            let percentage = Int(progress * 100)
            saveStateLabel.text = "保存中...\(percentage)%"
        case .saved:
            saveStateLabel.isHidden = false
            saveStateLabel.setIcon(
                prefixText: "",
                icon: .fontAwesomeSolid(.save),
                iconColor: .green,
                postfixText: "  保存済み",
                postfixTextColor: .originSecondaryLabel,
                size: nil
            )
        }
    }
}
