//
//  AuthViewController.swift
//  GoYo
//
//  Created by 方品中 on 2023/5/27.
//
import Firebase
import GoogleSignIn
import UIKit
import CryptoKit
import AuthenticationServices
import FirebaseAuth
import AVFoundation
import CoreML
import Vision
var model: VNCoreMLModel!

class AuthViewController: UIViewController {
    // Unhashed nonce.
    fileprivate var currentNonce: String?
    
    let videoURL = URL(fileURLWithPath: Bundle.main.path(forResource: "HomePage", ofType: "mp4")!)
    var player: AVQueuePlayer?
    var looper: AVPlayerLooper?
    
    @IBOutlet weak var playerView: UIView!
    @IBOutlet weak var buttonView: UIView! {
        didSet {
            self.buttonView.layer.cornerRadius = 25
        }
    }

    @IBOutlet weak var googleSignIn: UIView! {
        didSet {
            let button = UIButton()
            button.addTarget(self, action: #selector(signInWithGoogle), for: .touchUpInside)
            
            let width = self.googleSignIn.frame.width
            let height = self.googleSignIn.frame.height

            button.frame = CGRect(x: 0, y: 0, width: width, height: height)
            button.contentVerticalAlignment = .center

            self.googleSignIn.addSubview(button)
        }
    }

    @IBOutlet weak var appleSignIn: UIView! {
        didSet {
            let button = UIButton()
            button.addTarget(self, action: #selector(startSignInWithAppleFlow), for: .touchUpInside)
            
            let width = self.appleSignIn.frame.width
            let height = self.appleSignIn.frame.height
            
            button.frame = CGRect(x: 0, y: 0, width: width, height: height)

            self.appleSignIn.addSubview(button)
        }
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.doLoadModel()
    }
    
    private func doLoadModel() {
        let defaultConfig = MLModelConfiguration()
        
        DispatchQueue.global().async {
            guard let YOLOmodel = try? VNCoreMLModel(for: YOLOv3(configuration: defaultConfig).model) else {
                print("無法載入模型")
                return
            }
            
            model = YOLOmodel
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        player = AVQueuePlayer(url: videoURL)
        looper = AVPlayerLooper(player: player!, templateItem: (player?.currentItem!)!)

        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = self.playerView.bounds
        playerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        self.playerView.layer.addSublayer(playerLayer)

        player!.play()
        
        if Auth.auth().currentUser != nil {
            self.performSegue(withIdentifier: "AuthComplete", sender: self)
        }
    }
    
    @objc private func signInWithGoogle() {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        
        let configuration = GIDConfiguration(clientID: clientID)
        
        GIDSignIn.sharedInstance.configuration = configuration
        
        GIDSignIn.sharedInstance.signIn(withPresenting: self) { [weak self] user, error in
            if let error = error {
                print(error.localizedDescription)
                
                return
            }
            
            guard let user = user?.user else { return }
            
            let credential = GoogleAuthProvider.credential(withIDToken: user.idToken!.tokenString, accessToken: user.accessToken.tokenString)
            
            self?.firebaseSignInWithGoogle(credential: credential)
        }
    }
    
    private func firebaseSignInWithGoogle(credential: AuthCredential) {
        Auth.auth().signIn(with: credential) { [weak self] _, error in
            if let error = error {
                print(error.localizedDescription)
                
                return
            }
            
            self?.performSegue(withIdentifier: "AuthComplete", sender: self)
        }
    }
    
    @IBAction func doAppleLogin(_ sender: UIButton) {
        self.startSignInWithAppleFlow()
    }
}

// Apple
extension AuthViewController {
    @objc func startSignInWithAppleFlow() {
        let nonce = randomNonceString()
        currentNonce = nonce
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.performRequests()
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError(
                "Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)"
            )
        }
        
        let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        
        let nonce = randomBytes.map { byte in
            // Pick a random character from the set, wrapping around if needed.
            charset[Int(byte) % charset.count]
        }
        
        return String(nonce)
    }
    
}

extension AuthViewController: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let nonce = currentNonce else {
                fatalError("Invalid state: A login callback was received, but no login request was sent.")
            }
            guard let appleIDToken = appleIDCredential.identityToken else {
                print("Unable to fetch identity token")
                return
            }
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                return
            }

            let credential = OAuthProvider.appleCredential(
                withIDToken: idTokenString,
                rawNonce: nonce,
                fullName: appleIDCredential.fullName
            )

            // Sign in with Firebase.
            Auth.auth().signIn(with: credential) { (_, error) in
                if let error = error {
                    print(error)

                    return
                }

                self.performSegue(withIdentifier: "AuthComplete", sender: self)
            }
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        // Handle error.
        print("Sign in with Apple errored: \(error)")
    }
}
