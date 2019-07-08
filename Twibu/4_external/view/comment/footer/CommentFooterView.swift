//
//  CommentFooterView.swift
//  Twibu
//
//  Created by abeyuya on 2019/07/07.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import UIKit

final class CommentFooterView: UIView {

    @IBOutlet weak var indicator: UIActivityIndicatorView!
    @IBOutlet weak var showTwitterButton: UIButton! {
        didSet {
            showTwitterButton.setIcon(
                prefixText: "",
                prefixTextColor: .clear,
                icon: .fontAwesomeBrands(.twitter),
                iconColor: .twitter,
                postfixText: " Twitterでもっと見る",
                postfixTextColor: .darkGray,
                backgroundColor: .clear,
                forState: .normal,
                textSize: nil,
                iconSize: nil
            )

            showTwitterButton.addTarget(self, action: #selector(tapShowTwitterButton), for: .touchUpInside)
        }
    }

    private var url: URL?

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

    func set(mode: Mode, url: URL) {
        self.url = url

        switch mode {
        case .hasMore:
            DispatchQueue.main.async {
                self.indicator.isHidden = false
                self.showTwitterButton.isHidden = true
            }
        case .finish:
            DispatchQueue.main.async {
                self.indicator.isHidden = true
                self.showTwitterButton.isHidden = false
            }
        case .hide:
            DispatchQueue.main.async {
                self.indicator.isHidden = true
                self.showTwitterButton.isHidden = true
            }
        }

        setNeedsLayout()
        layoutIfNeeded()
    }

    @objc
    private func tapShowTwitterButton() {
        guard let url = url else { return }

        DispatchQueue.main.async {
            UIApplication.shared.open(url, options: [:])
        }

        AnalyticsDispatcer.logging(
            .showMoreTwitterTap,
            param: ["url": url]
        )
    }
}
