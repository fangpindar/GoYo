//
//  LoadingUtil.swift
//  GoYo
//
//  Created by 方品中 on 2023/6/13.
//
import UIKit
import Lottie

class LoadingUtil {
    static var shared = LoadingUtil()

    private var loadingView = LottieAnimationView(name: "loading.json")

    func doShowLoading(target: UIView) {
        let size = target.frame.width
        loadingView.frame = CGRect(x: 0, y: 0, width: size, height: size)

        loadingView.center = target.center

        loadingView.loopMode = LottieLoopMode.playOnce

        loadingView.animationSpeed = 2

        target.addSubview(loadingView)

        loadingView.play()
    }

    func doStopLoading() {
        loadingView.removeFromSuperview()
    }
}
