//
//  FollowViewController.swift
//  GoYo
//
//  Created by 方品中 on 2023/6/7.
//
import Firebase
import UIKit

class FollowViewController: UIViewController {
    @IBOutlet weak var followTableView: UITableView! {
        didSet {
            self.followTableView.delegate = self
            self.followTableView.dataSource = self
        }
    }
    
    var users = [User]()
    var type = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.getFollowByType()
    }
    
    private func getFollowByType() {
        let ref = Firestore.firestore().collection("follows")
        
        ref.whereField(self.type, isEqualTo: Auth.auth().currentUser?.uid as Any).order(by: "createTime", descending: true).getDocuments { snapshot, error in
            if let error = error {
                print(error)
            } else {
                let group = DispatchGroup()
                let target = (self.type == "self" ? "others" : "self")
                self.users = []

                snapshot?.documents.forEach { document in
                    if let userId =  document.data()[target] as? String {
                        let userRef = Firestore.firestore().collection("users").document(userId)
                        group.enter()

                        userRef.getDocument { document, error in
                            defer {
                                group.leave()
                            }

                            if let error = error {
                                print(error)
                            } else {
                                guard let document = document, document.exists else {
                                    print("Document does not exist")
                                    return
                                }

                                let data = document.data()!

                                if let name = data["name"] as? String,
                                   let id = data["id"] as? String,
                                   let imageURL = data["imageURL"] as? String {
                                    self.users.append(
                                        User(
                                            name: name,
                                            id: id,
                                            imageURL: URL(string: imageURL)
                                        )
                                    )
                                }
                            }
                        }
                    }
                }

                group.notify(queue: .main) { [weak self] in
                    self?.followTableView.reloadData()
                }
            }
        }
    }
}

extension FollowViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.users.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "SettingTableViewCell", for: indexPath) as? SettingTableViewCell else {
            return UITableViewCell()
        }

        let user = self.users[indexPath.row]

        cell.settingImageView.loadImage(user.imageURL?.absoluteString)
        cell.settingLabel.text = user.name
        cell.user = user

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? SettingTableViewCell,
           let user = cell.user,
           let profileViewController = UIStoryboard.profile.instantiateViewController(withIdentifier: "ProfileViewController") as? ProfileViewController {

            profileViewController.user = user

            self.navigationController?.pushViewController(profileViewController, animated: true)
        }
    }
}
