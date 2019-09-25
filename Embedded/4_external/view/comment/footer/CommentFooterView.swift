//
//  CommentFooterView.swift
//  Twibu
//
//  Created by abeyuya on 2019/07/07.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import UIKit
import SafariServices

final class CommentFooterView: UIView {
    @IBOutlet private weak var indicator: UIActivityIndicatorView! {
        didSet {
            if #available(iOS 13, *) {
                indicator.style = .medium
            }
        }
    }
    @IBOutlet private weak var showTwitterButton: UIButton! {
        didSet {
            showTwitterButton.setIcon(
                prefixText: "",
                prefixTextColor: .clear,
                icon: .fontAwesomeBrands(.twitter),
                iconColor: .twitter,
                postfixText: " Twitterでもっと見る",
                postfixTextColor: .originLabel,
                backgroundColor: .clear,
                forState: .normal,
                textSize: nil,
                iconSize: nil
            )

            showTwitterButton.addTarget(self, action: #selector(tapShowTwitterButton), for: .touchUpInside)
        }
    }

    private var tapAction: () -> Void = {}

    enum Mode {
        case hasMore, finish, hide
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        loadNib()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        loadNib()
    }

    private func loadNib() {
        guard let view = Bundle(for: type(of: self)).loadNibNamed(
            String(describing: type(of: self)),
            owner: self,
            options: nil)?.first as? UIView else { return }

        view.frame = self.bounds
        self.addSubview(view)
    }

    func set(mode: Mode, tapAction: @escaping () -> Void) {
        self.tapAction = tapAction

        defer {
            setNeedsLayout()
            layoutIfNeeded()
        }

        switch mode {
        case .hasMore:
            self.indicator.isHidden = false
            self.showTwitterButton.isHidden = true
        case .finish:
            self.indicator.isHidden = true
            self.showTwitterButton.isHidden = false
        case .hide:
            self.indicator.isHidden = true
            self.showTwitterButton.isHidden = true
        }
    }

    @objc
    private func tapShowTwitterButton() {
        tapAction()
    }
}
