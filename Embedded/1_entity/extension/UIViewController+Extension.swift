//
//  UIViewController+Extension.swift
//  Twibu
//
//  Created by abeyuya on 2019/06/22.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import UIKit

public extension UIViewController {
    func showAlert(title: String?, message: String) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        let okAction = UIAlertAction(title: "OK", style: .cancel)
        alert.addAction(okAction)

        DispatchQueue.main.async {
            self.present(alert, animated: true)
        }
    }
}

public protocol StoryboardInstantiatable {}

public extension StoryboardInstantiatable where Self: UIViewController {
    static func initFromStoryBoard() -> Self {
        let storyboard = UIStoryboard(
            name: String(describing: self),
            bundle: Bundle(for: Self.self)
        )
        let vc = storyboard.instantiateInitialViewController() as! Self
        return vc
    }
}
