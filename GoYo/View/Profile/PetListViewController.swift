//
//  PetListViewController.swift
//  GoYo
//
//  Created by 方品中 on 2023/6/8.
//
import Firebase
import UIKit

struct Pet {
    var id: String
    var name: String
}

class PetListViewController: UIViewController {
    var pets = [Pet]()
    @IBSegueAction func presentAdd(_ coder: NSCoder) -> AddPetViewController? {
        let controller = AddPetViewController(coder: coder)

        controller!.doGetPets = self.doGetPets
        
        if let sheetPresentationController = controller?.sheetPresentationController {
            sheetPresentationController.detents = [.medium()]
        }

        return controller
    }
    
    @IBOutlet weak var petListTableView: UITableView! {
        didSet {
            self.petListTableView.delegate = self
            self.petListTableView.dataSource = self
        }
    }
    
    @IBAction func doAddClick(_ sender: UIButton) {
        self.performSegue(withIdentifier: "goAdd", sender: self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
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
                
                self?.petListTableView.reloadData()
            }
        }
    }
}

extension PetListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.pets.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "PetListTableViewCell", for: indexPath) as? PetListTableViewCell else {
            return UITableViewCell()
        }
        
        let pet = self.pets[indexPath.row]
        
        cell.nameLabel.text = pet.name
        cell.petInfo = pet
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let cell = tableView.cellForRow(at: indexPath) as? PetListTableViewCell else { return UISwipeActionsConfiguration() }
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { (_, _, _) in

            let ref = Firestore.firestore().collection("pets").document(cell.petInfo.id)

            ref.delete { error in
                if let error = error {
                    print(error)
                } else {
                    self.doGetPets()
                }
            }
        }
        
        deleteAction.backgroundColor = .red
        
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        return configuration
    }
}
