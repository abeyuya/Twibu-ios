//
//  ArticleCell.swift
//  Embedded
//
//  Created by abeyuya on 2019/10/04.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import UIKit

public final class ArticleCell: UITableViewCell {
    @IBOutlet private weak var mainView: CategoryContentView!

    public func set(bookmark: Bookmark, alreadyRead: Bool, showImage: Bool) {
        mainView.set(bookmark: bookmark, alreadyRead: alreadyRead, showImage: showImage)
    }

    public func set(saveState: CategoryContentView.SaveState) {
        mainView.set(saveState: saveState)
    }
}
