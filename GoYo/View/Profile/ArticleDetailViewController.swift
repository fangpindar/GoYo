//
//  ArticleDetailViewController.swift
//  GoYo
//
//  Created by 方品中 on 2023/6/1.
//
import UIKit
import Firebase
// import Hashtags

class ArticleDetailViewController: UIViewController {
    var article: Article!
    var comments = [Comment]()
    
    @IBOutlet weak var userImage: UIImageView! {
        didSet {
            self.userImage.loadImage(Auth.auth().currentUser?.photoURL?.absoluteString)
            self.userImage.layer.cornerRadius
            = self.userImage.frame.height / 2
        }
    }

    @IBOutlet weak var articlcesTableView: UITableView! {
        didSet {
            self.articlcesTableView.delegate = self
            self.articlcesTableView.dataSource = self
        }
    }
    
    @IBOutlet weak var editButton: UIButton!

    @IBOutlet weak var commentTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if self.article.creator != Auth.auth().currentUser?.uid {
            self.editButton.isHidden = true
        }
        
        self.tabBarController?.tabBar.isHidden = true
        
        self.doGetComments()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }
    
    private func doGetLike(completion: @escaping (Bool) -> Void) {
        let likes = Firestore.firestore().collection("likes")

        likes.document("\(self.article.id)\(Auth.auth().currentUser!.uid)").getDocument { document, _ in
            if let document = document {
                completion(document.exists)
            }
        }
    }
    
    private func doGetComments() {
        let comments = Firestore.firestore().collection("comments")
        self.comments = []

        comments.whereField("articleId", isEqualTo: self.article.id).order(by: "createTime", descending: true).getDocuments { [weak self] (snapshot, error) in
            if let error = error {
                print(error)
            } else {
                snapshot?.documents.forEach { document in
                    let commentData = document.data()
                    
                    if let name = commentData["creatorName"] as? String,
                       let time = commentData["createTime"] as? TimeInterval,
                       let comment = commentData["comment"] as? String,
                       let imageURL = commentData["imageURL"] as? String {
                        self?.comments.append(
                            Comment(
                                name: name,
                                time: Date(timeIntervalSince1970: time).date2String(dateFormat: "yyyy.MM.dd HH:mm:ss"),
                                comment: comment,
                                imageURL: imageURL
                            )
                        )
                    }
                }
                
                self?.articlcesTableView.reloadData()
            }
        }
    }
    
    @IBAction func doAddComment(_ sender: UIButton) {
        let comments = Firestore.firestore().collection("comments")
        
        let data: [String: Any] = [
            "createTime": Date().timeIntervalSince1970,
            "creator": Auth.auth().currentUser!.uid,
            "articleId": self.article.id,
            "creatorName": Auth.auth().currentUser?.displayName as Any,
            "comment": self.commentTextField.text as Any,
            "imageURL": Auth.auth().currentUser!.photoURL!.absoluteString
        ]
        
        comments.document().setData(data) { [weak self] error in
            if let error = error {
                print(error)
            } else {
                self?.commentTextField.text = ""
                self?.doGetComments()
            }
        }
    }
    
    @IBAction func doEditArticle(_ sender: UIButton) {
        guard let addArticleViewController = UIStoryboard.article.instantiateViewController(withIdentifier: "AddArticleViewController") as? AddArticleViewController else { return }
        
        let imageURLs: [URL] = self.article.medias.map { media in
            if let media = media.media as? String {
                return URL(string: media)!
            } else {
                return URL(string: "")!
            }
        }
        
        self.loadImages(from: imageURLs) { [weak self] images in
            addArticleViewController.viewModel.model = (self?.article)!
            addArticleViewController.viewModel.model.medias = images.map { image in
                return MediaInfo(
                    type: "photo",
                    media: image as Any
                )
            }
            
            self?.navigationController?.pushViewController(addArticleViewController, animated: true)
        }
    }
    
    private func loadImages(from urls: [URL], completion: @escaping ([UIImage?]) -> Void) {
        var images: [UIImage?] = []
        let dispatchGroup = DispatchGroup()
        
        for url in urls {
            dispatchGroup.enter()
            
            loadImage(from: url) { (image) in
                images.append(image)
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            completion(images)
        }
    }
    
    private func loadImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
        URLSession.shared.dataTask(with: url) { (data, _, error) in
            guard let data = data, error == nil else {
                completion(nil)
                return
            }
            
            let image = UIImage(data: data)
            completion(image)
        }.resume()
    }
}

extension ArticleDetailViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.article.medias.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCollectionViewCell", for: indexPath) as? PhotoCollectionViewCell else {
            return UICollectionViewCell()
        }
        
        cell.photoImageView.loadImage(self.article.medias[indexPath.row].media as? String)
        
        return cell
    }
}

extension ArticleDetailViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.comments.count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "ArticleTableViewCell", for: indexPath) as? ArticleTableViewCell else { return UITableViewCell() }
                        
            cell.setCollectionView(medias: self.article.medias)
            
//            cell.hashtagView.removeTags()
            
//            article.hashTags.forEach { hashTag in
//                let tag = HashTag(word: hashTag.replacingOccurrences(of: "#", with: ""), isRemovable: false)
//                cell.hashtagView.addTag(tag: tag)
//                cell.hashtags.append(tag)
//            }
            
            self.doGetLike { isLike in
                cell.isLike = isLike
            }
            
            cell.nameButton.setTitle(article.creatorName, for: UIControl.State.normal)
            cell.article = article
            cell.creator = article.creator
            cell.timeLabel.text = Date(timeIntervalSince1970: article.createTime).date2String(dateFormat: "yyyy.MM.dd")
            cell.contentLabel.text = article.content
            
            return cell
        } else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "CommentTableViewCell", for: indexPath) as? CommentTableViewCell else { return UITableViewCell() }
            
            let comment = self.comments[indexPath.row - 1]
            
            cell.nameLabel.text = comment.name
            cell.timeLabel.text = comment.time
            cell.commentLabel.text = comment.comment
            cell.photoImageView.loadImage(comment.imageURL)
            
            return cell
        }
    }
}
