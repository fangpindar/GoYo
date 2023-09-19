//
//  StartWalkingViewController.swift
//  GoYo
//
//  Created by 方品中 on 2023/6/10.
//
import Lottie
import UIKit

class StartWalkingViewController: UIViewController {
    @IBOutlet weak var animateView: UIView! {
        didSet {
            let animationView = LottieAnimationView(name: "waiting.json")
            let width = self.animateView.frame.width
            let height = self.animateView.frame.height
            
            animationView.frame = CGRect(x: 0, y: 0, width: width - 8, height: height)
            // animationView.center = self.animateView.center
            animationView.loopMode = LottieLoopMode.loop
            
            animationView.animationSpeed = 1.0
            
            animateView.addSubview(animationView)
            
            animationView.play()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}
