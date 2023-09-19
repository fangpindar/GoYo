//
//  UIView+Extension.swift
//  GoYo
//
//  Created by 方品中 on 2023/6/26.
//
import UIKit

extension UIView {
    var sideLengths: [CGFloat] {
        return [self.frame.width, self.frame.height]
    }
    
    var minLength: CGFloat {
        return self.sideLengths.min() ?? 0
    }
    
    func doSetRadius() {
        self.doSetRadius(radius: self.minLength / 2)
    }
    
    func doSetRadius(radius: CGFloat) {
        self.layer.cornerRadius = radius
    }
}
