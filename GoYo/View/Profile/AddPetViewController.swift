//
//  AddPetViewController.swift
//  GoYo
//
//  Created by 方品中 on 2023/6/8.
//
import Firebase
import UIKit

class AddPetViewController: UIViewController {
    var doGetPets: (() -> Void)?

    @IBOutlet weak var nameTextField: UITextField!
    
    @IBOutlet weak var birthDatePicker: UIDatePicker!
    
    @IBOutlet weak var genderSegmentedControl: UISegmentedControl!
    
    @IBOutlet weak var breedTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func doAddPet(_ sender: UIButton) {
        let ref = Firestore.firestore().collection("pets").document()
        
        let data = [
            "creatTime": Date().timeIntervalSince1970,
            "creator": Auth.auth().currentUser!.uid,
            "id": ref.documentID,
            "name": self.nameTextField.text as Any,
            "birth": self.birthDatePicker.date.timeIntervalSince1970,
            "gender": self.genderSegmentedControl.selectedSegmentIndex,
            "breed": self.breedTextField.text as Any
        ] as [String: Any]
        
        ref.setData(data) { [weak self] error in
            if let error = error {
                print(error)
            } else {
                self?.doGetPets!()
                self?.dismiss(animated: true)
            }
        }
    }
}
