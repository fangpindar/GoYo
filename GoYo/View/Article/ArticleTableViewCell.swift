//
//  ArticleTableViewCell.swift
//  GoYo
//
//  Created by 方品中 on 2023/5/28.
//
import UIKit
import Firebase

class ArticleTableViewCell: UITableViewCell {
    @IBOutlet weak var cardView: UIView! {
        didSet {
            self.cardView.layer.cornerRadius = 10
//            self.layer.shadowRadius = 2
//            self.layer.shadowOpacity = 0.1
        }
    }
    
    @IBOutlet weak var goSettingButton: UIButton!
    
    @IBOutlet weak var moreImageView: UIImageView!
    
    var mediaInfos = [MediaInfo]()
    var images = [UIImage]()
//    var hashtags = [HashTag]()
    var creator: String! {
        didSet {
            let ref = Firestore.firestore().collection("users")
            
            ref.document(creator).getDocument { [weak self] documentSnap, _ in
                if let documentSnap = documentSnap {
                    if documentSnap.exists {
                        if let imageURL = documentSnap.data()!["imageURL"] as? String {
                            self?.userImageView.loadImage(imageURL)
                        }
                    }
                }
            }
        }
    }
    var article: Article! {
        didSet {
            
        }
    }
    
    var doSetArticleId: ((String) -> Void)?
    var isLike: Bool! {
        didSet {
            if self.isLike {
//                self.likeButton.setTitle("Unlike", for: UIControl.State.normal)
                self.likeButton.setImage(UIImage(named: "like"), for: UIControl.State.normal)
                self.likeButton.tintColor = .red
            } else {
//                self.likeButton.setTitle("Like", for: UIControl.State.normal)
                self.likeButton.setImage(UIImage(named: "unlike"), for: UIControl.State.normal)
                self.likeButton.tintColor = .blue
            }
        }
    }

    @IBOutlet weak var userImageView: UIImageView! {
        didSet {
            self.userImageView.layer.cornerRadius = self.userImageView.bounds.width / 2
            self.userImageView.layer.masksToBounds = true
        }
    }
    @IBOutlet weak var nameButton: UIButton!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var imageCollectionView: UICollectionView!
    
    @IBOutlet weak var pageControl: UIPageControl!
        
    @IBOutlet weak var contentLabel: UILabel!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var replyButton: UIButton!
//    @IBOutlet weak var hashtagView: HashtagView! {
//        didSet {
//            self.hashtagView.delegate = self
//            self.hashtagView.containerPaddingLeft = 0
//            self.hashtagView.containerPaddingBottom = 0
//            self.hashtagView.tagTextColor = UIColor(hex: "#464646FF")!
//            self.hashtagView.tagBackgroundColor = UIColor(hex: "#D9D9D9FF")!
//        }
//    }

    @IBOutlet weak var heightConstraint: NSLayoutConstraint!

    @IBOutlet weak var hashTagConstraint: NSLayoutConstraint!
    
    @IBAction func doGoComment() {
        self.doSetArticleId!(self.article.id)
    }
    
    @IBAction func doLike(_ sender: UIButton) {
        self.isLike = !self.isLike
        
        let ref = Firestore.firestore().collection("likes").document("\(self.article.id)\(Auth.auth().currentUser?.uid ?? "")")
        
        if self.isLike {
            let data = [
                "userId": Auth.auth().currentUser?.uid as Any,
                "articleId": self.article.id
            ] as [String: Any]
            
            ref.setData(data)
        } else {
            ref.delete()
        }
    }
    
    func setCollectionView(medias: [MediaInfo]) {
        self.mediaInfos = medias
        
        if self.mediaInfos.count > 1 {
            self.moreImageView.isHidden = false
        } else {
            self.moreImageView.isHidden = true
        }
        
        self.imageCollectionView.dataSource = self
        self.imageCollectionView.delegate = self
        self.imageCollectionView.reloadData()
        
        self.heightConstraint.constant = self.frame.width
        
        self.pageControl.numberOfPages = medias.count
    }
}

extension ArticleTableViewCell: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.mediaInfos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCollectionViewCell", for: indexPath) as? PhotoCollectionViewCell else {
            return UICollectionViewCell()
        }
        
        cell.photoImageView.loadImage(self.mediaInfos[indexPath.row].media as? String)
        
        return cell
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let pageWidth = imageCollectionView.frame.size.width
        let currentPage = Int((imageCollectionView.contentOffset.x + pageWidth / 2) / pageWidth)
        pageControl.currentPage = currentPage
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = self.frame.width
        return CGSize(width: width, height: width)
    }
}

//extension ArticleTableViewCell: HashtagViewDelegate {
//    func hashtagRemoved(hashtag: Hashtags.HashTag) {
//        self.hashtags.remove(at: self.hashtags.firstIndex(of: hashtag)!)
//    }
//
//    func viewShouldResizeTo(size: CGSize) {
//        self.hashTagConstraint.constant = size.height
//
//        UIView.animate(withDuration: 0.4) {
//            self.layoutIfNeeded()
//        }
//    }
//}
