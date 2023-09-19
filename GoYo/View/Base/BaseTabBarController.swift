//
//  BaseTabBarController.swift
//  GoYo
//
//  Created by 方品中 on 2023/5/25.
//
import UIKit
import Firebase

class BaseTabBarController: UITabBarController {
    private let tabs: [Tabs] = [.article, .walking, .memory, .profile]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.insertUserInfo()
        
        self.viewControllers = tabs.map { $0.makeViewController() }
    }
    
    private func insertUserInfo() {
        guard let currentUser = Auth.auth().currentUser else { return }
        
        let data: [String: Any] = [
            "id": currentUser.uid,
            "name": currentUser.displayName ?? "",
            "email": currentUser.email!,
            "imageURL": currentUser.photoURL?.absoluteString ?? ""
        ]

        Firestore.firestore().collection("users").document(currentUser.uid).setData(data) { err in
            if let err = err {
                print("Error writing document: \(err)")
            } else {
                print("Document successfully written!")
            }
        }
    }
}

// MARK: Tabs
extension BaseTabBarController {
    private enum Tabs: String {
        case article = "Article"
        case walking = "Walking"
        case memory = "Memory"
        case profile = "Profile"
        
        func makeViewController() -> UIViewController {
            let controller: UIViewController
            switch self {
            case .article: controller = UIStoryboard.article.instantiateInitialViewController()!
            case .walking: controller = UIStoryboard.walking.instantiateInitialViewController()!
            case .memory: controller = UIStoryboard.memory.instantiateInitialViewController()!
            case .profile: controller = UIStoryboard.profile.instantiateInitialViewController()!
            }
            
            controller.tabBarItem = makeTabBarItem()
            controller.tabBarItem.imageInsets = UIEdgeInsets(top: 6.0, left: 0.0, bottom: -6.0, right: 0.0)
            return controller
        }
        
        private func makeTabBarItem() -> UITabBarItem {
            return UITabBarItem(title: self.rawValue, image: image, selectedImage: image)
        }
        
        private var image: UIImage? {
            switch self {
            case .article:
                return UIImage(named: "Article")
            case .walking:
                return UIImage(named: "Walk")
            case .memory:
                return UIImage(named: "Calendar")
            case .profile:
                return UIImage(named: "Profile")
            }
        }
        
        private var selectedImage: UIImage? {
            switch self {
            case .article:
                return UIImage(named: "Article")
            case .walking:
                return UIImage(named: "Walk")
            case .memory:
                return UIImage(named: "Calendar")
            case .profile:
                return UIImage(named: "Profile")
            }
        }
    }
}
