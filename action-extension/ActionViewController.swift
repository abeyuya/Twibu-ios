//
//  ActionViewController.swift
//  action-extension
//
//  Created by abeyuya on 2019/09/22.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import UIKit
import MobileCoreServices
import Embedded

private let typeId = kUTTypeURL as String

final class ActionViewController: UIViewController {
    @IBOutlet private weak var indicator: UIActivityIndicatorView! {
        didSet {
            if #available(iOS 13, *) {
                indicator.style = .medium
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCloseButton()

        getUrlItem { result in
            switch result {
            case .failure(let e):
                self.showAlert(title: nil, message: e.displayMessage)
            case .success(let urlStr):
                CommentRepositoryApi.shared.fetchBookmarkAndCommentsApi(bookmarkUrl: urlStr) { [weak self] result in
                    self?.indicator.stopAnimating()
                    switch result {
                    case .failure(let e):
                        self?.showAlert(title: nil, message: e.displayMessage)
                    case .success(let res):
                        DispatchQueue.main.async {
                            self?.setupCommentView(res: res)
                        }
                    }
                }
            }
        }
    }

    private func setupCommentView(res: CommentRepositoryApi.ApiResponse) {
        let v: UIView = {
            let vc = CommentRootViewController<ApiCommentListViewModel>.build(bookmark: res.bookmark)
            let container = UIView()
            container.translatesAutoresizingMaskIntoConstraints = false

            addChild(vc)
            vc.view.frame = container.frame

            container.addSubview(vc.view)
            vc.didMove(toParent: self)
            return container
        }()

        self.view.addSubview(v)
        v.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        v.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        v.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        v.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
    }

    private func setupCloseButton() {
        let b = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(done))
        navigationItem.setRightBarButton(b, animated: false)
    }

    private func getUrlItem(completion: @escaping (Result<String>) -> Void) {
        guard let inputItems = extensionContext?.inputItems as? [NSExtensionItem] else {
            completion(.failure(TwibuError.unknown("inputItemsがない")))
            return
        }

        guard let provider = inputItems[0].attachments?[0] else {
            completion(.failure(TwibuError.unknown("attachments.providerがない")))
            return
        }

        guard provider.hasItemConformingToTypeIdentifier(typeId) else {
            completion(.failure(TwibuError.unknown("itemTypeがURLじゃない")))
            return
        }

        provider.loadItem(forTypeIdentifier: typeId, options: nil) { item, error in
            if let error = error {
                completion(.failure(TwibuError.unknown(error.localizedDescription)))
                return
            }

            guard let url = item as? URL else {
                completion(.failure(TwibuError.unknown("URLが不正")))
                return
            }

            completion(.success(url.absoluteString))
        }
    }
    
    @objc
    private func done() {
        // Return any edited content to the host app.
        // This template doesn't do anything, so we just echo the passed in items.
        self.extensionContext!.completeRequest(
            returningItems: self.extensionContext!.inputItems,
            completionHandler: nil
        )
    }
}
