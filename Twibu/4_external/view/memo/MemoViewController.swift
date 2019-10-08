//
//  MemoViewController.swift
//  Embedded
//
//  Created by abeyuya on 2019/07/31.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import UIKit
import Embedded
import UnderKeyboard
import FirebaseFirestore

final public class MemoViewController: UIViewController, StoryboardInstantiatable {
    @IBOutlet private weak var navigationBar: UINavigationBar!
    @IBOutlet private weak var bottomLayoutConstraint: NSLayoutConstraint!
    @IBOutlet private weak var textView: UITextView!
    @IBOutlet private weak var blurView: UIVisualEffectView!

    private let underKeyboardLayoutConstraint = UnderKeyboardLayoutConstraint()
    private var oldMemo: Memo?

    private var userUid: String!
    private var bookmarkUid: String!

    override public func viewDidLoad() {
        super.viewDidLoad()
        setupNavigation()
        setupTextView()

        underKeyboardLayoutConstraint.setup(bottomLayoutConstraint, view: view)
        blurView.layer.cornerRadius = 8
        blurView.clipsToBounds = true

        MemoRepository.fetchMemo(userUid: userUid, bookmarkUid: bookmarkUid) { [weak self] result in
            switch result {
            case .failure(let e):
                Logger.print(e)
            case .success(let memo):
                DispatchQueue.main.async {
                    self?.oldMemo = memo
                    self?.textView.text = memo.memo
                }
            }
        }
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

    public func setParam(userUid: String, bookmarkUid: String) {
        self.userUid = userUid
        self.bookmarkUid = bookmarkUid
    }

    @objc
    private func tapCancelButton() {
        textView.resignFirstResponder()
        dismiss(animated: true)
    }

    @objc
    private func tapSaveButton() {
        textView.resignFirstResponder()
        MemoRepository.saveMemo(
            userUid: userUid,
            bookmarkUid: bookmarkUid,
            memo: textView.text,
            isNew: oldMemo == nil
        ) { result in
            switch result {
            case .success(_):
                break
            case .failure(let e):
                Logger.print(e)
            }
        }
        dismiss(animated: true)

        AnalyticsDispatcer.logging(.saveMemo, param: nil)
    }
}
