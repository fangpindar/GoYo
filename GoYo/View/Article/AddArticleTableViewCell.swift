//
//  AddArticleTableViewCell.swift
//  GoYo
//
//  Created by 方品中 on 2023/5/25.
//
import UIKit
// import Hashtags

class AddArticleTableViewCell: UITableViewCell {
//    var hashtags = [HashTag]()
    var setHashtags: (([String]) -> Void)!
    var setContent: ((String) -> Void)!
    
    @IBOutlet weak var photoCollectionView: UICollectionView!
    @IBOutlet weak var contentTextView: UITextView!
//    @IBOutlet weak var hashtagView: HashtagView!
    @IBOutlet weak var hashtagTextView: UITextField!
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    
    @IBAction func doAddHashtag(_ sender: Any) {
        if self.hashtagTextView.text != "" {
//            let tag = HashTag(word: self.hashtagTextView.text!, isRemovable: true)
            
//            self.hashtagView.addTag(tag: tag)
//            self.hashtags.append(tag)
//            self.setHashtags(self.hashtags.map { hashtag in return hashtag.text })
            self.hashtagTextView.text = ""
        }
    }
    
    func setCell() {
        if self.contentTextView.text == "" {
            self.contentTextView.text = "分享你的心情吧！"
            self.contentTextView.textColor = UIColor.placeholderText
            self.contentTextView.layer.borderColor = UIColor.placeholderText.cgColor
            self.contentTextView.layer.cornerRadius = 4
            self.contentTextView.layer.borderWidth = 0.5
        }

        self.contentTextView.layer.borderColor = UIColor.clear.cgColor
        self.contentTextView.delegate = self
        
//        self.hashtagView.delegate = self
        
        self.layoutIfNeeded()
    }
}

extension AddArticleTableViewCell: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == UIColor.placeholderText {
            textView.text = nil
            textView.textColor = UIColor.black
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "分享你的心情吧！"
            textView.textColor = UIColor.placeholderText
            
            self.setContent("")
        } else {
            self.setContent(textView.text)
        }
    }
}

//extension AddArticleTableViewCell: HashtagViewDelegate {
//    func hashtagRemoved(hashtag: Hashtags.HashTag) {
//        self.hashtags.remove(at: self.hashtags.firstIndex(of: hashtag)!)
//    }
//
//    func viewShouldResizeTo(size: CGSize) {
//        self.heightConstraint.constant = size.height
//
//        UIView.animate(withDuration: 0.4) {
//            self.layoutIfNeeded()
//        }
//    }
//}
