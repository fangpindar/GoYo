//
//  AddMemoryViewController.swift
//  GoYo
//
//  Created by 方品中 on 2023/5/30.
//
import UIKit
import Firebase

class AddMemoryViewController: UIViewController {
    var getMemories: ((@escaping () -> Void) -> Void)?
    var setMemoriesForTableView: (() -> Void)?
    var memory: Memory?
    var pets = [Pet]()

    var selectPet = ""
    var selectPetName = ""
    
    @IBOutlet weak var titleTextField: UITextField!

    @IBOutlet weak var datePicker: UIDatePicker!

    @IBOutlet weak var labelColorWell: UIColorWell! {
        didSet {
            self.labelColorWell.addTarget(self, action: #selector(colorWellChanged(_:)), for: UIControl.Event.valueChanged)
        }
    }
    
    @objc func colorWellChanged(_ sender: Any) {
        self.labelColorView.backgroundColor = self.labelColorWell.selectedColor
    }
    
    @IBOutlet weak var labelColorView: UIView!

    @IBOutlet weak var repeatTypeSegementedControl: UISegmentedControl!
    
    @IBOutlet weak var dogPickerView: UIPickerView! {
        didSet {
            self.dogPickerView.delegate = self
            self.dogPickerView.dataSource = self
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.labelColorView.isUserInteractionEnabled = false
        
        if let memory = self.memory {
            self.titleTextField.text = memory.title
            self.datePicker.date = Date(timeIntervalSince1970: memory.time)
            self.labelColorWell.selectedColor = UIColor(hex: memory.color)
            self.repeatTypeSegementedControl.selectedSegmentIndex = memory.repeatType
        }
        
        self.doGetPets()
    }

    private func doGetPets() {
        let ref = Firestore.firestore().collection("pets")

        ref.whereField("creator", isEqualTo: Auth.auth().currentUser!.uid).order(by: "creatTime", descending: true).getDocuments { [weak self] snapshot, error in
            if let error = error {
                print(error)
            } else {
                self?.pets = []

                snapshot?.documents.forEach { document in
                    let data = document.data()
                    
                    if let id = data["id"] as? String,
                       let name = data["name"] as? String {
                        self?.pets.append(Pet(id: id, name: name))
                    }
                }

                self?.dogPickerView.reloadAllComponents()
            }
        }
    }

    @IBAction func doDismiss(_ sender: UIButton) {
        self.dismiss(animated: true)
    }

    @IBAction func doAddMemory(_ sender: UIButton) {
        let memories = Firestore.firestore().collection("memories")

        let dateComponents = Calendar.current.dateComponents(
            in: TimeZone.current,
            from: self.datePicker.date
        )

        var repeatValue = ""

        switch self.repeatTypeSegementedControl.selectedSegmentIndex {
        case 0, 1:
            repeatValue = ""
        case 2:
            repeatValue = "\(dateComponents.weekday!)"
        case 3:
            repeatValue = "\(dateComponents.day!)"
        case 4:
            repeatValue = "\((dateComponents.month! * 100) + dateComponents.day!)"
        default:
            return
        }

        let data: [String: Any] = [
            "createTime": Date().timeIntervalSince1970,
            "creator": Auth.auth().currentUser!.uid,
            "title": self.titleTextField.text as Any,
            "time": self.datePicker.date.timeIntervalSince1970 as Any,
            "pet": self.selectPet,
            "color": self.labelColorView.backgroundColor!.hexString() as Any,
            "repeatType": self.repeatTypeSegementedControl.selectedSegmentIndex,
            "repeatValue": repeatValue,
            "type": 0 // 0: Memory
        ]

        let document: DocumentReference?

        if self.memory == nil {
            document = memories.document()
        } else {
            document = memories.document(self.memory!.documentId)
        }

        document!.setData(data) { [weak self] error in
            if let error = error {
                print(error)
            } else {
                self?.getMemories! {
                    self?.setMemoriesForTableView!()
                }

                let content = UNMutableNotificationContent()
                content.title = "GoYo提醒～"
                content.subtitle = self?.selectPetName ?? ""
                content.body = "別忘了 \(self?.titleTextField.text ?? "") ~"
                content.sound = UNNotificationSound.default

                // repeatType = 0, 0
                // repeatType = 1, 0
                // repeatType = 2, 星期
                // repeatType = 3, 日
                // repeatType = 4, 月日
                // var repeatValue: String
                var components = DateComponents()
                let repeatType = self?.repeatTypeSegementedControl.selectedSegmentIndex
                var isRepeat = false
                let dateComponents = Calendar.current.dateComponents(
                    in: TimeZone.current,
                    from: (self?.datePicker.date)!
                )
                
                components.hour = dateComponents.hour
                components.minute = dateComponents.minute
                
                // 0: 不重複
                if repeatType == 0 {
                    components.month = dateComponents.month
                    components.day = dateComponents.day
                    
                    isRepeat = false
                }
                
                // 1: 每天
                if repeatType == 1 {
                    components.month = dateComponents.month
                    components.day = dateComponents.day
                    isRepeat = true
                }
                
                // 2: 每週
                if repeatType == 2 {
                    components.weekday = dateComponents.weekday
                    isRepeat = true
                }
                
                // 3: 每月
                if repeatType == 3 {
                    components.day = dateComponents.day

                    isRepeat = true
                }
                
                // 4: 每年
                if repeatType == 4 {
                    components.year = dateComponents.year
                    components.month = dateComponents.month
                    components.day = dateComponents.day
                    
                    isRepeat = true
                }

                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: isRepeat)

                let request = UNNotificationRequest(identifier: document?.documentID ?? "", content: content, trigger: trigger)
                
                UNUserNotificationCenter.current().add(request, withCompletionHandler: {error in
                    if let error = error {
                        print(error)
                    } else {
                        print("成功建立通知...")
                    }
                })

                self?.dismiss(animated: true)
            }
        }
    }
}

extension AddMemoryViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.pets.count + 1
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if row == 0 {
            return ""
        }
        
        return self.pets[row - 1].name
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if row == 0 {
            self.selectPet = ""
            self.selectPetName = ""
        } else {
            self.selectPet = self.pets[row - 1].id
            self.selectPetName = self.pets[row - 1].name
        }
    }
}
