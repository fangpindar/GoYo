//
//  ReportViewController.swift
//  GoYo
//
//  Created by 方品中 on 2023/6/7.
//
import Firebase
import UIKit
import JGProgressHUD

class ReportViewController: UIViewController {
    @IBOutlet weak var contentView: UITextView!

    var othersId: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func doSendReport(_ sender: UIButton) {
        let ref = Firestore.firestore().collection("reports").document()
        
        let data = [
            "reporter": Auth.auth().currentUser?.uid as Any,
            "othersId": self.othersId,
            "content": self.contentView.text as Any
        ] as [String: Any]

        let hud = JGProgressHUD()
        hud.indicatorView = JGProgressHUDSuccessIndicatorView()
        hud.textLabel.text = "感謝您的回報，將會有專人進行確認與處理"
        hud.show(in: self.view)
        
        ref.setData(data) { error in
            if let error = error {
                print(error)
            }
            
            hud.dismiss(animated: true)
            self.dismiss(animated: true)
        }
    }
}
