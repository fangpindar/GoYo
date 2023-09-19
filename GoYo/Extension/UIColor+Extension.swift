//
//  UIColor+Extension.swift
//  GoYo
//
//  Created by 方品中 on 2023/5/30.
//
import UIKit

extension UIColor {
    public convenience init?(hex: String) {
        let rgbR, rgbG, rgbB, rgbA: CGFloat

        if hex.hasPrefix("#") {
            let start = hex.index(hex.startIndex, offsetBy: 1)
            let hexColor = String(hex[start...])

            if hexColor.count == 8 {
                let scanner = Scanner(string: hexColor)
                var hexNumber: UInt64 = 0

                if scanner.scanHexInt64(&hexNumber) {
                    rgbR = CGFloat((hexNumber & 0xFF000000) >> 24) / 255
                    rgbG = CGFloat((hexNumber & 0x00FF0000) >> 16) / 255
                    rgbB = CGFloat((hexNumber & 0x0000FF00) >> 8) / 255
                    rgbA = CGFloat(hexNumber & 0x000000FF) / 255

                    self.init(red: rgbR, green: rgbG, blue: rgbB, alpha: rgbA)
                    return
                }
            }
        }

        return nil
    }
    
    func hexString() -> String {
        let components = self.cgColor.components
        let red: CGFloat = components?[0] ?? 0.0
        let green: CGFloat = components?[1] ?? 0.0
        let blue: CGFloat = components?[2] ?? 0.0
        let alpha: CGFloat = components?[3] ?? 0.0

        let hex = String.init(format: "#%02lX%02lX%02lX%02lX", lroundf(Float(red * 255)), lroundf(Float(green * 255)), lroundf(Float(blue * 255)), lroundf(Float(alpha * 255)))

        return hex
     }
    
    static let color1 = UIColor(named: "Color1")
    static let color2 = UIColor(named: "Color2")
    static let color3 = UIColor(named: "Color3")
    static let color4 = UIColor(named: "Color4")
    static let color5 = UIColor(named: "Color5")
}
