//
//  UIImageView+Extension.swift
//  GoYo
//
//  Created by 方品中 on 2023/5/29.
//
import UIKit
import Kingfisher

extension UIImageView {
    func loadImage(_ urlString: String?) {
        guard let urlString = urlString else { return }
        let url = URL(string: urlString)
        self.kf.setImage(with: url, placeholder: UIImage(named: "GoYo"))
    }
}
