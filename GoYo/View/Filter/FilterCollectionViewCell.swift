//
//  FilterCollectionViewCell.swift
//  GoYo
//
//  Created by 方品中 on 2023/5/24.
//

import UIKit

class FilterCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView! {
        didSet {
            self.imageView.layer.cornerRadius = 10
        }
    }
    @IBOutlet weak var filterLabel: UILabel!
}
