//
//  SettingViewController.swift
//  GoYo
//
//  Created by 方品中 on 2023/6/6.
import UIKit
import Firebase

struct Setting {
    var image: String
    var label: String
}

class SettingViewController: UIViewController {
    var settings = [Setting]()

    var doRefreshArticle: (() -> ())?
    
    var user: User!

    @IBOutlet weak var settingTableView: UITableView! {
        didSet {
            self.settingTableView.delegate = self
            self.settingTableView.dataSource = self
        }
    }

    @IBSegueAction func performPet(_ coder: NSCoder) -> PetListViewController? {
        let controller = PetListViewController(coder: coder)

        if let sheetPresentationController = controller?.sheetPresentationController {
            sheetPresentationController.detents = [.medium()]
        }

        return controller
    }

    @IBSegueAction func doRepoet(_ coder: NSCoder) -> ReportViewController? {
        let controller = ReportViewController(coder: coder)

        controller?.othersId = self.user.id

        if let sheetPresentationController = controller?.sheetPresentationController {
            sheetPresentationController.detents = [.medium()]
        }

        return controller
    }

    @IBSegueAction func performReport(_ coder: NSCoder) -> ReportViewController? {
        let controller = ReportViewController(coder: coder)

        controller?.othersId = self.user.id

        if let sheetPresentationController = controller?.sheetPresentationController {
            sheetPresentationController.detents = [.medium()]
        }

        return controller
    }
    
    @IBSegueAction func doShowPolicy(_ coder: NSCoder) -> PolicyViewController? {
        let controller = PolicyViewController(coder: coder)

        if let sheetPresentationController = controller?.sheetPresentationController {
            sheetPresentationController.detents = [.medium()]
        }

        return controller
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.doSetSettings()
    }

    private func doSetSettings() {
        self.settings = []

        if Auth.auth().currentUser?.uid == self.user.id {
            self.settings.append(Setting(image: "Dog", label: "狗狗管理"))
            self.settings.append(Setting(image: "Policy", label: "隱私權政策"))
            self.settings.append(Setting(image: "DeleteUser", label: "刪除帳號"))
            self.settings.append(Setting(image: "Logout", label: "登出"))
        } else {
            let ref = Firestore.firestore().collection("blocks")
            ref.document("\(Auth.auth().currentUser!.uid)\(self.user?.id ?? "")").getDocument { [weak self] snapShot, error in
                if let error = error {
                    print(error)
                } else {
                    if let snapShot = snapShot {
                        if snapShot.exists {
                            self?.settings.append(Setting(image: "Person-Off", label: "解除封鎖"))
                        } else {
                            self?.settings.append(Setting(image: "Person", label: "封鎖"))
                        }
                    }
                }
                
                self?.settings.append(Setting(image: "Report", label: "檢舉"))
                self?.settingTableView.reloadData()
            }
        }
    }
}

extension SettingViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.settings.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "SettingTableViewCell", for: indexPath) as? SettingTableViewCell else { return UITableViewCell() }

        let setting = self.settings[indexPath.row]

        cell.settingLabel.text = setting.label
        cell.settingImageView.image = UIImage(named: setting.image)
        cell.accessibilityIdentifier = setting.label
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        
        let accessibilityIdentifier = cell?.accessibilityIdentifier

        // 狗狗管理
        if accessibilityIdentifier == "狗狗管理" {
            self.performSegue(withIdentifier: "goAddDog", sender: self)
        }

        // 登出
        if accessibilityIdentifier == "登出" {
            do {
                try Auth.auth().signOut()
                self.presentingViewController?.presentingViewController?.dismiss(animated: true)
            } catch {
                print("Error")
            }
        }

        // 封鎖
        if accessibilityIdentifier == "封鎖" {
            let ref = Firestore.firestore().collection("blocks")
            let document = ref.document("\(Auth.auth().currentUser!.uid)\(self.user?.id ?? "")")
            
            let data = [
                "self": Auth.auth().currentUser!.uid,
                "others": self.user?.id as Any
            ] as [String: Any]
            
            document.setData(data) { [weak self] error in
                if let error = error {
                    print(error)
                } else {
                    getBlock()
                    self?.doSetSettings()
                    if let doRefreshArticle = self?.doRefreshArticle {
                        doRefreshArticle()
                    }
                }
            }
        }
        
        // 解除封鎖
        if accessibilityIdentifier == "解除封鎖" {
            let ref = Firestore.firestore().collection("blocks")
            let document = ref.document("\(Auth.auth().currentUser!.uid)\(self.user?.id ?? "")")
            
            document.delete { [weak self] error in
                if let error = error {
                    print(error)
                } else {
                    getBlock()
                    self?.doSetSettings()
                }
            }
        }
        
        // 檢舉
        if accessibilityIdentifier == "檢舉" {
            self.performSegue(withIdentifier: "doReport", sender: self)
        }
        
        // 隱私權政策
        if accessibilityIdentifier == "隱私權政策" {
            self.performSegue(withIdentifier: "doShowPolicy", sender: self)
        }
        
        // 刪除帳號
        if accessibilityIdentifier == "刪除帳號" {
            let controller = UIAlertController(title: "刪除帳號", message: "是否確認刪除帳號？\n刪除後將不可復原！", preferredStyle: .alert)
            
            let okAction = UIAlertAction(title: "好的", style: .default) { [weak self] _ in
                self?.doDeleteUser()
            }
            let cancelAction = UIAlertAction(title: "取消", style: .cancel)
            
            controller.addAction(okAction)
            controller.addAction(cancelAction)
            present(controller, animated: true)
        }
    }

    func doDeleteUser() {
        let authId = Auth.auth().currentUser?.uid
        
        let collections = [
            "articles", "blocks", "blocks",
            "comments", "follows", "follows",
            "likes", "memories", "pets",
            "users", "walks"
        ]
        let field = [
            "authorId", "self", "others",
            "creator", "self", "others",
            "userId", "creator", "creator",
            "id", "authorId"
        ]
        
        let group = DispatchGroup()
        
        collections.enumerated().forEach { index, collection in
            group.enter()
            
            let articlesRef = Firestore.firestore().collection(collection)
            let fieldString = field[index]
            
            articlesRef.whereField(fieldString, isEqualTo: authId ?? "").getDocuments { snapshot, error in
                defer {
                    group.leave()
                }
                
                if let error = error {
                    print(error)
                } else {
                    let batch = Firestore.firestore().batch()

                    snapshot?.documents.forEach { document in
                        batch.deleteDocument(articlesRef.document(document.documentID))
                    }
                    
                    batch.commit()
                }
            }
        }
        
        group.notify(queue: .main) {
            self.presentingViewController?.presentingViewController?.dismiss(animated: true)
            
            do {
                try Auth.auth().signOut()
            } catch {
                print("ERROR")
            }
        }
    }
}
