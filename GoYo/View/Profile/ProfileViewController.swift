//
//  ProfileViewController.swift
//  GoYo
//
//  Created by 方品中 on 2023/5/25.
//
import UIKit
import Firebase

struct User {
    var name: String
    var id: String
    var imageURL: URL?
}

class ProfileViewController: UIViewController {
    var articles = [Article]()
    var user: User?
    var selectArticle: Article?
    var distance: Double = 0
    var isFollow = false {
        didSet {
            if self.isFollow {
                self.followButton.setImage(UIImage(named: "unfollow"), for: UIControl.State.normal)
            } else {
                self.followButton.setImage(UIImage(named: "follow"), for: UIControl.State.normal)
            }
            
            self.doGetFollowers()
            self.doGetFollowing()
        }
    }
    
    @IBOutlet weak var centerView: UIView! {
        didSet {
            let view = UIView()
            view.frame.size = CGSize(width: 1, height: 28)
            
        }
    }
    
    @IBSegueAction func goSetting(_ coder: NSCoder) -> SettingViewController? {
        let controller = SettingViewController(coder: coder)
        
        controller?.user = self.user
        
        if let sheetPresentationController = controller?.sheetPresentationController {
            sheetPresentationController.detents = [.medium()]
        }
        
        return controller
    }
    
    @IBOutlet weak var settingButton: UIButton! {
        didSet {
            self.settingButton.contentHorizontalAlignment = .right
            self.settingButton.tintColor = UIColor(hex: "#747474FF")
        }
    }
    
    @IBOutlet weak var profileCollectionView: UICollectionView! {
        didSet {
            self.profileCollectionView.delegate = self
            self.profileCollectionView.dataSource = self
        }
    }
    @IBOutlet weak var profileImageView: UIImageView! {
        didSet {
            self.profileImageView.layer.cornerRadius = self.profileImageView.bounds.width / 2
            self.profileImageView.layer.masksToBounds = true
        }
    }
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var mileageImageView: UIImageView!
    @IBOutlet weak var mileageLabel: UILabel!
    @IBOutlet weak var followButton: UIButton!
    
    @IBOutlet weak var postLabel: UILabel!
    
    var type = ""
    @IBOutlet weak var followingButton: UIButton! {
        didSet {
            if self.user == nil {
                self.followingButton.isEnabled = true
            } else {
                self.followingButton.isEnabled = false
            }
        }
    }
    @IBOutlet weak var followerButton: UIButton! {
        didSet {
            if self.user == nil {
                self.followerButton.isEnabled = true
            } else {
                self.followerButton.isEnabled = false
            }
        }
    }
    
    @IBAction func doFollowingClick(_ sender: UIButton) {
        self.type = "self"
        self.performSegue(withIdentifier: "goFollow", sender: self)
    }
    
    @IBAction func doFollowerClick(_ sender: UIButton) {
        self.type = "others"
        self.performSegue(withIdentifier: "goFollow", sender: self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.followButton.isHidden = true
        
        if self.user == nil {
            let currentUser = Auth.auth().currentUser!
            self.user = User(
                name: currentUser.displayName ?? "",
                id: currentUser.uid,
                imageURL: currentUser.photoURL
            )
            
            self.settingButton.setImage(UIImage(named: "setting"), for: UIControl.State.normal)
        } else {
            self.settingButton.setImage(UIImage(named: "info"), for: UIControl.State.normal)

            let ref = Firestore.firestore().collection("follows").document("\(Auth.auth().currentUser!.uid)\(self.user?.id ?? "")")
            if self.user!.id != Auth.auth().currentUser!.uid {
                ref.getDocument { [weak self] documentSnap, _ in
                    if let documentSnap = documentSnap {
                        if documentSnap.exists {
                            self?.isFollow = true
                            self?.followButton.setImage(UIImage(named: "unfollow"), for: UIControl.State.normal)
                        } else {
                            self?.isFollow = false
                            self?.followButton.setImage(UIImage(named: "follow"), for: UIControl.State.normal)
                        }
                        self?.followButton.isHidden = false
                    }
                }
            }
        }
        
        self.nameLabel.text = self.user?.name
        self.profileImageView.loadImage(self.user?.imageURL?.absoluteString)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.doGetArticles()
        self.doGetWalks()
        self.doGetFollowers()
        self.doGetFollowing()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? ArticleDetailViewController {
            destination.article = self.selectArticle
        }
        
        if let destination = segue.destination as? FollowViewController {
            destination.type = self.type
        }
    }
    
    private func doGetArticles() {
        let ref = Firestore.firestore().collection("articles")
        
        ref.whereField("authorId", isEqualTo: self.user?.id as Any).order(by: "createTime", descending: true).getDocuments { [weak self] (snapshot, error) in
            if let error = error {
                print(error)
            } else {
                self?.articles = []
                
                snapshot?.documents.forEach { [weak self] document in
                    let article = document.data()
                    
                    if let createTime = article["createTime"] as? TimeInterval,
                       let creator = article["authorId"] as? String,
                       let creatorName = article["authorName"] as? String,
                       let hashTags = article["hashtags"] as? [String],
                       let medias = article["medias"] as? [[String: String]],
                       let content = article["content"] as? String {
                        self?.articles.append(
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
                    
                    self?.profileCollectionView.reloadData()
                    self?.postLabel.text = "\(self?.articles.count ?? 0)"
                }
            }
        }
    }
    
    private func doGetWalks() {
        let ref = Firestore.firestore().collection("walks")
        
        ref.whereField("authorId", isEqualTo: self.user?.id ?? "").getDocuments { [weak self] (snapshot, error) in
            if let error = error {
                print(error)
            } else {
                self?.distance = 0
                
                snapshot?.documents.forEach { [weak self] document in
                    let data = document.data()
                    
                    if let distance = data["distance"] as? String {
                        self?.distance += Double(distance) ?? 0
                    }
                }
                
                self?.doSetReward()
            }
        }
    }
    
    private func doGetFollowers() {
        let ref = Firestore.firestore().collection("follows")
        
        ref.whereField("others", isEqualTo: self.user!.id).getDocuments { snapShot, error in
            if let error = error {
                print(error)
            } else {
                self.followerButton.setTitle("\(snapShot?.count ?? 0)", for: UIControl.State.normal)
            }
        }
    }
    
    private func doGetFollowing() {
        let ref = Firestore.firestore().collection("follows")
        
        ref.whereField("self", isEqualTo: self.user!.id).getDocuments { snapShot, error in
            if let error = error {
                print(error)
            } else {
                self.followingButton.setTitle("\(snapShot?.count ?? 0)", for: UIControl.State.normal)
            }
        }
    }
    
    private func doSetReward() {
        var arrival: Int = 0
        
        rewards.enumerated().forEach { (index, reward) in
            if self.distance >= reward.distanceL && self.distance < reward.distanceH {
                arrival = index
            }
        }
        
        let level = rewards[arrival].level
        
        if arrival == rewards.count - 1 {
            self.mileageLabel.text = "\(level)"
        } else {
            // let delta = rewards[arrival + 1].distanceL - self.distance
            
            if self.user?.id == Auth.auth().currentUser?.uid {
                self.mileageLabel.text = "\(level)"
            } else {
                self.mileageLabel.text = "\(level)"
            }
        }
    }
    
    @IBAction func doLogOut(_ sender: UIButton) {
        self.performSegue(withIdentifier: "goSetting", sender: self)
    }
    
    @IBAction func doFollow(_ sender: UIButton) {
        let ref = Firestore.firestore().collection("follows").document("\(Auth.auth().currentUser!.uid)\(self.user?.id ?? "")")
        if self.isFollow {
            ref.delete {_ in
                self.isFollow = false
            }
        } else {
            let data = [
                "self": Auth.auth().currentUser!.uid,
                "others": self.user?.id as Any,
                "createTime": Date().timeIntervalSince1970
            ] as [String: Any]
            ref.setData(data) {_ in
                self.isFollow = true
            }
        }
    }
}

extension ProfileViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.articles.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCollectionViewCell", for: indexPath) as? PhotoCollectionViewCell else {
            return UICollectionViewCell()
        }
        
        cell.photoImageView.loadImage(self.articles[indexPath.row].medias.first?.media as? String)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let size = (self.view.frame.width - 4 ) / 3
        
        return CGSize(width: size, height: size)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.selectArticle = self.articles[indexPath.row]
        
        self.performSegue(withIdentifier: "goArticleDetail", sender: self)
    }
}
