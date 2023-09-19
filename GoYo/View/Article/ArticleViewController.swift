//
//  ArticleViewController.swift
//  GoYo
//
//  Created by 方品中 on 2023/5/25.
//
import UIKit
import Firebase
import EasyRefresher
// import Hashtags

class ArticleViewController: UIViewController {
    var articles = [Article]()
    var selectedArticleId = ""
    var likeArticles = [String]()
    var selectedUser: User!
    
    @IBSegueAction func doSetting(_ coder: NSCoder) -> SettingViewController? {
        let controller = SettingViewController(coder: coder)
        
        controller!.user = self.selectedUser

        controller!.doRefreshArticle = {
            self.doShowLoading()
            
            getBlock {
                self.getArticles()
            }
        }
        
        if let sheetPresentationController = controller?.sheetPresentationController {
            sheetPresentationController.detents = [.medium()]
        }
        
        return controller
    }
    
    @IBOutlet weak var addArticleView: UIView! {
        didSet {
            self.addArticleView.doSetRadius()
        }
    }

    @IBOutlet weak var addArticleImageView: UIImageView! {
        didSet {
            self.addArticleImageView.loadImage(Auth.auth().currentUser?.photoURL?.absoluteString)
            self.addArticleImageView.doSetRadius()
        }
    }
    
    @IBOutlet weak var articleTableView: UITableView! {
        didSet {
            self.articleTableView.delegate = self
            self.articleTableView.dataSource = self
            self.articleTableView.contentInset = UIEdgeInsets.init(top: 8, left: 0, bottom: 8, right: 0)
        }
    }
    
    @IBSegueAction func presentSegue(_ coder: NSCoder) -> CommentViewController? {
        let controller = CommentViewController(coder: coder)

        controller?.articleId = self.selectedArticleId
        
        if let sheetPresentationController = controller?.sheetPresentationController {
            sheetPresentationController.detents = [.medium()]
        }

        return controller
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.articles = []
        self.articleTableView.reloadData()
        
        self.doShowLoading()
        
        getBlock {
            self.getArticles()
        }
    }
    
    func getArticles(completion: @escaping () -> Void = {}) {
        let articlesRef = Firestore.firestore().collection("articles")

        self.articles = []
        
        var query: Query!
        
        if !blocks.isEmpty {
            query = articlesRef.order(by: "authorId", descending: true).whereField("authorId", notIn: blocks).order(by: "createTime", descending: true)
        } else {
            query = articlesRef.order(by: "createTime", descending: true)
        }
        
        query.getDocuments { (snapshot, error) in
            if let error = error {
                print(error)
            } else {
                snapshot?.documents.forEach { document in
                    let article = document.data()

                    if let createTime = article["createTime"] as? TimeInterval,
                       let creator = article["authorId"] as? String,
                       let creatorName = article["authorName"] as? String,
                       let hashTags = article["hashtags"] as? [String],
                       let medias = article["medias"] as? [[String: String]],
                       let content = article["content"] as? String {
                        self.articles.append(
                            Article(
                                id: document.documentID,
                                createTime: createTime,
                                creator: creator,
                                creatorName: creatorName,
                                pets: [],
                                hashTags: hashTags,
                                medias: medias.map { media in
                                    return MediaInfo(
                                        type: media["type"] ?? "",
                                        media: media["media"] as Any
                                    )
                                },
                                content: content
                            )
                        )
                    }
                }
                
                let ref = Firestore.firestore().collection("likes")
                
                ref.whereField("userId", isEqualTo: Auth.auth().currentUser?.uid as Any).getDocuments { (snapshot, error) in
                    if let error = error {
                        print(error)
                    } else {
                        self.likeArticles = []
                        
                        snapshot?.documents.forEach { document in
                            let like = document.data()

                            if let articleId = like["articleId"] as? String {
                                self.likeArticles.append(articleId)
                            }
                        }
                    }

                    self.articleTableView.reloadData()
                    
                    self.doStopLoading()
                    
                    completion()
                }
            }
        }
    }
}

extension ArticleViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.articles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ArticleTableViewCell", for: indexPath) as? ArticleTableViewCell else { return UITableViewCell() }
        
        let article = self.articles[indexPath.row]

//        cell.hashtagView.removeTags()
        
//        article.hashTags.forEach { hashTag in
//            let tag = HashTag(word: hashTag.replacingOccurrences(of: "#", with: ""), isRemovable: false)
//            cell.hashtagView.addTag(tag: tag)
//        }
        
        cell.nameButton.setTitle(article.creatorName, for: .normal)
        cell.nameButton.accessibilityIdentifier = article.creator
        cell.nameButton.addTarget(self, action: #selector(buttonClicked),
                                  for: .touchUpInside)
        
        cell.article = article
        
        cell.isLike = self.likeArticles.contains(article.id)
        
        cell.creator = article.creator
        cell.timeLabel.text = Date(timeIntervalSince1970: article.createTime).date2String(dateFormat: "yyyy.MM.dd")
        cell.contentLabel.text = article.content
        cell.doSetArticleId = { [weak self] articleId in
            self?.selectedArticleId = articleId
            self?.performSegue(withIdentifier: "goComment", sender: self)
        }

        cell.setCollectionView(medias: self.articles[indexPath.row].medias)
        
        cell.goSettingButton.addTarget(self, action: #selector(goSetting), for: .touchUpInside)
        
        cell.goSettingButton.accessibilityValue = self.articles[indexPath.row].creator

        return cell
    }
    
    @objc func goSetting(sender: UIButton) {
        
        self.selectedUser = User(name: "", id: sender.accessibilityValue!)
        
        self.performSegue(withIdentifier: "doSetting", sender: self)
    }
    
    @objc func buttonClicked(sender: UIButton) {
        if let profileViewController = UIStoryboard.profile.instantiateViewController(withIdentifier: "ProfileViewController") as? ProfileViewController {
            let targetId = sender.accessibilityIdentifier!
            
            Firestore.firestore().collection("users").document(targetId).getDocument { (document, _) in
                guard let document = document, document.exists else {
                    print("Document does not exist")
                    return
                }
                
                let data = document.data()!
                
                if let name = data["name"] as? String,
                   let id = data["id"] as? String,
                   let imageURL = data["imageURL"] as? String {
                    profileViewController.user = User(
                        name: name,
                        id: id,
                        imageURL: URL(string: imageURL)!
                    )
                }
                
                if profileViewController.user?.id == Auth.auth().currentUser!.uid {
                    profileViewController.settingButton.isHidden = true
                }
                
                self.navigationController?.pushViewController(profileViewController, animated: true)
            }
        }
    }
}
