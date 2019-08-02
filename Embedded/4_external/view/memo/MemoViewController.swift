//
//  MemoViewController.swift
//  Embedded
//
//  Created by abeyuya on 2019/07/31.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import UIKit
import UnderKeyboard

final public class MemoViewController: UIViewController, StoryboardInstantiatable {
    @IBOutlet private weak var navigationBar: UINavigationBar!
    @IBOutlet private weak var bottomLayoutConstraint: NSLayoutConstraint!
    @IBOutlet private weak var textView: UITextView!
    @IBOutlet private weak var blurView: UIVisualEffectView!

    let underKeyboardLayoutConstraint = UnderKeyboardLayoutConstraint()

    override public func viewDidLoad() {
        super.viewDidLoad()
        setupNavigation()
        setupTextView()

        underKeyboardLayoutConstraint.setup(bottomLayoutConstraint, view: view)
        blurView.layer.cornerRadius = 8
        blurView.clipsToBounds = true
    }

    private func setupNavigation() {
        let cancelButton = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(tapCancelButton)
        )
        navigationBar.topItem?.leftBarButtonItem = cancelButton

        let saveButton = UIBarButtonItem(
            barButtonSystemItem: .save,
            target: self,
            action: #selector(tapSaveButton)
        )
        navigationBar.topItem?.rightBarButtonItem = saveButton
    }

    private func setupTextView() {
        textView.becomeFirstResponder()
        textView.textContainerInset = .init(top: 12, left: 12, bottom: 12, right: 12)
    }

    @objc
    private func tapCancelButton() {
        textView.resignFirstResponder()
        dismiss(animated: true)
    }

    @objc
    private func tapSaveButton() {
        dismiss(animated: true)
    }
}
