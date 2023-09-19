//
//  CommentViewController.swift
//  GoYo
//
//  Created by 方品中 on 2023/5/31.
//
import UIKit
import Firebase

struct Comment {
    var name: String
    var time: String
    var comment: String
    var imageURL: String
}

class CommentViewController: UIViewController {
    var comments = [Comment]()
    var articleId: String?

    @IBOutlet weak var commentsTableView: UITableView! {
        didSet {
            self.commentsTableView.delegate = self
            self.commentsTableView.dataSource = self
        }
    }
    
    @IBOutlet weak var userImage: UIImageView! {
        didSet {
            self.userImage.layer.cornerRadius = self.userImage.frame.height / 2
            self.userImage.loadImage(Auth.auth().currentUser?.photoURL?.absoluteString)
        }
    }
    
    @IBOutlet weak var commentTextField: UITextField! {
        didSet {
            self.commentTextField.layer.cornerRadius = self.commentTextField.frame.height / 2
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.doGetComments()
    }
    
    private func doGetComments() {
        let comments = Firestore.firestore().collection("comments")
        print(self.articleId!)
        self.comments = []

        comments.whereField("articleId", isEqualTo: self.articleId!).order(by: "createTime", descending: true).getDocuments { [weak self] (snapshot, error) in
            if let error = error {
                print(error)
            } else {
                snapshot?.documents.forEach { document in
                    let commentData = document.data()
                    
                    if let name = commentData["creatorName"] as? String,
                       let time = commentData["createTime"] as? TimeInterval,
                       let comment = commentData["comment"] as? String,
                       let imageURL = commentData["imageURL"] as? String{
                        self?.comments.append(
                            Comment(
                                name: name,
                                time: Date(timeIntervalSince1970: time).date2String(dateFormat: "yyyy.MM.dd"),
                                comment: comment,
                                imageURL: imageURL
                            )
                        )
                    }
                }
                
                self?.commentsTableView.reloadData()
            }
        }
    }

    @IBAction func doAddComment(_ sender: UIButton) {
        let comments = Firestore.firestore().collection("comments")
        
        let data: [String: Any] = [
            "createTime": Date().timeIntervalSince1970,
            "creator": Auth.auth().currentUser!.uid,
            "articleId": self.articleId as Any,
            "creatorName": Auth.auth().currentUser?.displayName as Any,
            "comment": self.commentTextField.text as Any,
            "imageURL": Auth.auth().currentUser!.photoURL!.absoluteString
        ]
        
        comments.document().setData(data) { [weak self] error in
            if let error = error {
                print(error)
            } else {
                // 重撈資料
                self?.commentTextField.text = ""
                self?.doGetComments()
            }
        }
    }
}

extension CommentViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.comments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "CommentTableViewCell", for: indexPath) as? CommentTableViewCell else { return UITableViewCell() }
        
        let comment = self.comments[indexPath.row]
        
        cell.nameLabel.text = comment.name
        cell.timeLabel.text = comment.time
        cell.commentLabel.text = comment.comment
        cell.photoImageView.loadImage(comment.imageURL)
        
        return cell
    }
}
