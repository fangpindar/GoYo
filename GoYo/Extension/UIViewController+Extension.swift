//
//  UIViewController+Extension.swift
//  GoYo
//
//  Created by 方品中 on 2023/6/13.
//
import UIKit

extension UIViewController {
    func doShowLoading() {
        LoadingUtil.shared.doShowLoading(target: self.view)
    }
    
    func doStopLoading() {
        LoadingUtil.shared.doStopLoading()
    }
}
