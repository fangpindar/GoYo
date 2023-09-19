//
//  WalkDoneViewController.swift
//  GoYo
//
//  Created by 方品中 on 2023/5/29.

import UIKit
import Firebase
import Lottie

struct Reward {
    var level: String
    var distanceL: Double
    var distanceH: Double
}

let rewards = [
    Reward(level: "遛狗等級：1", distanceL: 0.0, distanceH: 1000.0),
    Reward(level: "遛狗等級：2", distanceL: 1000.0, distanceH: 5000.0),
    Reward(level: "遛狗等級：3", distanceL: 5000.0, distanceH: 10000.0),
    Reward(level: "遛狗等級：4", distanceL: 10000.0, distanceH: 20000.0),
    Reward(level: "遛狗等級：5", distanceL: 20000.0, distanceH: 50000.0),
    Reward(level: "遛狗等級：6", distanceL: 50000.0, distanceH: 100000.0),
    Reward(level: "遛狗等級：7", distanceL: 100000.0, distanceH: 999999999999.0)
]

class WalkDoneViewController: UIViewController {
    var distance: String!
    var originDiatance = 0.0
    var originLevelIndex: Int!
    
    @IBOutlet weak var awardView: UIView! {
        didSet {
            self.awardView.layer.cornerRadius = self.awardView.frame.height / 2
            self.awardView.layer.borderWidth = 1
            self.awardView.layer.borderColor = UIColor(hex: "#D77418FF")!.cgColor
        }
    }
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet var animateView: UIView!
    @IBOutlet weak var levelLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.navigationItem.hidesBackButton = true
        self.timer = CADisplayLink(target: self, selector: #selector(updateLabel))
        
        let data: [String: Any] = [
            "createTime": Date().timeIntervalSince1970,
            "authorId": Auth.auth().currentUser!.uid as Any,
            "authorName": Auth.auth().currentUser!.displayName as Any,
            "distance": self.distance as Any
        ]
        
        Firestore.firestore().collection("walks").whereField("authorId", isEqualTo: Auth.auth().currentUser!.uid).getDocuments { snapshot, error in
            if let error = error {
                print(error)
            } else {
                snapshot?.documents.forEach { document in
                    let data = document.data()
                    
                    if let distance = data["distance"] as? String {
                        self.originDiatance += Double(distance) ?? 0.0
                    }
                }

                rewards.enumerated().forEach { (index, reward) in
                    if self.originDiatance >= reward.distanceL && self.originDiatance < reward.distanceH {
                        self.originLevelIndex = index
                    }
                }

                print(self.originDiatance)
                print(self.originLevelIndex as Any)
                
                if self.originLevelIndex == 6 {
                    self.levelLabel.text = rewards[self.originLevelIndex].level
                } else {
                    var nextLevel = self.originLevelIndex
                    let totalDistance = self.originDiatance + (Double(self.distance) ?? 0.0)
                    rewards.enumerated().forEach { (index, reward) in
                        if totalDistance  >= reward.distanceL && totalDistance < reward.distanceH {
                            nextLevel = index
                        }
                    }
                    
                    if nextLevel != self.originLevelIndex {
                        print("升等")
                        self.doShowAnimate("levelup.json", 1)
                    } else {
                        self.doShowAnimate("walkingdog.json", 2)
                    }

                    self.levelLabel.text = rewards[nextLevel!].level
                }
                
                self.destinationValue = self.originDiatance + Double(self.distance)!
                                
                self.timer?.add(to: .main, forMode: RunLoop.Mode.default)

                self.startTime = CACurrentMediaTime()

                Firestore.firestore().collection("walks").document().setData(data) { error in
                    if let error = error {
                        print(error)
                    }
                }
            }
        }
    }
    
    private func doShowAnimate(_ name: String, _ speed: Int) {
        let animationView = LottieAnimationView(name: name)
        let width = self.animateView.frame.width
        let height = self.animateView.frame.height

        if speed == 1 {
            animationView.frame = CGRect(x: 0, y: 0, width: width, height: height)
        } else {
            animationView.frame = CGRect(x: 8, y: 0, width: width, height: height)
        }
        
//        animationView.center = self.animateView.center
        
        animationView.loopMode = LottieLoopMode.loop
        
        animationView.animationSpeed = CGFloat(speed)
        
        self.animateView.addSubview(animationView)
        
        animationView.play()
    }
    
    @IBAction func doWalkDone(_ sender: UIButton) {
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    var timer: CADisplayLink?
    var startTime: CFTimeInterval = 0.0
    let duration: CFTimeInterval = 0.5
    var destinationValue = 0.0
    
    @objc func updateLabel() {
         let elapsed = CACurrentMediaTime() - startTime
         
         if elapsed >= duration {
             timer?.invalidate()
             timer = nil
             self.distanceLabel.text = String(format: "%.0f m", destinationValue)
             self.performAnimation()
         } else {
             let progress = elapsed / duration
             let count = progress * destinationValue
             self.distanceLabel.text = String(format: "%.0f m", count)
         }
     }
    
    func performAnimation() {
        UIView.animate(withDuration: 0.5, delay: 0.0, options: [.autoreverse], animations: {
            self.distanceLabel.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        }, completion: nil)
    }
}
