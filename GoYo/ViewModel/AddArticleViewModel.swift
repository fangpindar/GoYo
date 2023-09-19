//
//  ArticleViewModel.swift
//  GoYo
//
//  Created by 方品中 on 2023/5/25.
//
import UIKit

class ArticleViewModel {
    var model = Article(
        id: "",
        createTime: 0,
        creator: "",
        creatorName: "",
        pets: [],
        hashTags: [],
        medias: [],
        content: ""
    )
    
    func onPetsChange(pets: [String]) {
        self.model.pets = pets
    }
    
    func onHashTagsChange(hashTags: [String]) {
        self.model.hashTags = hashTags
    }
    
    func onMediasChange(medias: [MediaInfo]) {
        self.model.medias = medias
    }
    
    func onContentChange(content: String) {
        self.model.content = content
    }
}
