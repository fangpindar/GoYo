//
//  PolicyViewController.swift
//  GoYo
//
//  Created by 方品中 on 2023/6/17.
//
import UIKit
import WebKit
import Firebase

class PolicyViewController: UIViewController {
    let webView: WKWebView! = nil
    
    var urlString: String!
    
    func doGetURLString() {
        let policyURL = Firestore.firestore().collection("PolicyURL")
        
        policyURL.document().getDocument { document, _ in
            if let document = document,
               let data = document.data(),
               let urlString = data["URL"] as? String {
                self.urlString = urlString
            }
        }
    }
    
    func doSetPolicyView() {
        let request = URLRequest(url: URL(string: urlString)!)
        
        webView.load(request)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: self.view.topAnchor),
            webView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
        
        self.doSetPolicyView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.tabBarController?.tabBar.isHidden = false
    }
}
