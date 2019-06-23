//
//  UIViewController+Extension.swift
//  Twibu
//
//  Created by abeyuya on 2019/06/22.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import UIKit

extension UIViewController {
    func showAlert(title: String?, message: String) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        let okAction = UIAlertAction(title: "OK", style: .cancel)
        alert.addAction(okAction)
        present(alert, animated: true)
    }
}

protocol StoryboardInstantiatable {}

extension StoryboardInstantiatable where Self: UIViewController {
    static func initFromStoryBoard() -> Self {
        let storyboard = UIStoryboard(name: String(describing: self), bundle: nil)
        let vc = storyboard.instantiateInitialViewController() as! Self
        return vc
    }
}
