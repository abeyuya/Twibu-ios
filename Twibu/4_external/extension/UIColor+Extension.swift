//
//  UIColor+Extension.swift
//  Twibu
//
//  Created by abeyuya on 2019/06/23.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import UIKit

extension UIColor {
    class func rgba(red: Int, green: Int, blue: Int, alpha: CGFloat) -> UIColor{
        return UIColor(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: alpha)
    }

    class var mainBlack: UIColor {
        return .rgba(red: 68, green: 68, blue: 68, alpha: 1)
    }

    class var tabBgGray: UIColor {
        return .rgba(red: 248, green: 248, blue: 248, alpha: 1)
    }

    class var tabUnselectGray: UIColor {
        return .rgba(red: 187, green: 187, blue: 187, alpha: 1)
    }
}
