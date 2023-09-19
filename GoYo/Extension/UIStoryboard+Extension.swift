//
//  UIStoryboard+Extension.swift
//  STYLiSH
//
//  Created by WU CHIH WEI on 2019/2/11.
//  Copyright © 2019 AppWorks School. All rights reserved.
//
import UIKit

extension UIStoryboard {
    static var main: UIStoryboard { return stStoryboard(name: "Main") }
    static var article: UIStoryboard { return stStoryboard(name: "Article") }
    static var walking: UIStoryboard { return stStoryboard(name: "Walking") }
    static var memory: UIStoryboard { return stStoryboard(name: "Memory") }
    static var profile: UIStoryboard { return stStoryboard(name: "Profile") }
    static var auth: UIStoryboard { return stStoryboard(name: "Auth") }

    private static func stStoryboard(name: String) -> UIStoryboard {
        return UIStoryboard(name: name, bundle: nil)
    }
}
