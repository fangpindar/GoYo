//
//  CommentTableViewCell.swift
//  GoYo
//
//  Created by 方品中 on 2023/5/31.
//

import UIKit

class CommentTableViewCell: UITableViewCell {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var commentLabel: UILabel!
    @IBOutlet weak var photoImageView: UIImageView! {
        didSet {
            self.photoImageView.layer.cornerRadius = self.photoImageView.frame.height / 2
        }
    }
    
    @IBOutlet weak var commentView: UIView! {
        didSet {
            self.commentView.layer.cornerRadius = 8
        }
    }
}
