//
//  CategoryViewController.swift
//  Twibu
//
//  Created by abeyuya on 2019/06/16.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import UIKit

class CategoryViewController: UIViewController {

    var category: PagingRootViewController.Category?

    override func viewDidLoad() {
        super.viewDidLoad()

        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.text = category?.rawValue
        view.addSubview(l)
        l.center = view.center
    }
}
