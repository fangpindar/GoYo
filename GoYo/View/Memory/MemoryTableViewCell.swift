//
//  MemoryTableViewCell.swift
//  GoYo
//
//  Created by 方品中 on 2023/5/30.
//

import UIKit

class MemoryTableViewCell: UITableViewCell {
    var memory: Memory!
    
    @IBOutlet weak var colorView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
}
