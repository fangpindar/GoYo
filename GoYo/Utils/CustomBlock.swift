//
//  CustomBlock.swift
//  GoYo
//
//  Created by 方品中 on 2023/6/7.
//
import Firebase

var blocks = [String]()

func getBlock(completion: @escaping () -> Void = {}) {
    let ref = Firestore.firestore().collection("blocks").whereField("self", isEqualTo: Auth.auth().currentUser!.uid)
    
    ref.getDocuments { snapshot, error in
        if let error = error {
            print(error)
        } else {
            snapshot?.documents.forEach { document in
                let data = document.data()
                
                if let others = data["others"] as? String {
                    blocks.append(others)
                }
            }
            
            completion()
        }
    }
}
