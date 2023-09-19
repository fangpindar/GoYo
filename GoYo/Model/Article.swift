//
//  Article.swift
//  GoYo
//
//  Created by 方品中 on 2023/5/25.
//
import UIKit

struct Article: Equatable {
    static func == (lhs: Article, rhs: Article) -> Bool {
        return lhs.id == rhs.id
    }
    
    var id: String
    var createTime: TimeInterval
    var creator: String
    var creatorName: String
    var pets: [String]
    var hashTags: [String]
    var medias: [MediaInfo]
    var content: String
}

struct MediaInfo {
    var type: String
    var media: Any
}
