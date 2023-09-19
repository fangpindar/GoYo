//
//  AddArticleViewController.swift
//  GoYo
//
//  Created by 方品中 on 2023/5/25.
//
import UIKit
import Firebase
import FirebaseStorage
import JGProgressHUD
import CoreML
import Vision
// import Hashtags

class AddArticleViewController: UIViewController {
    
    @IBOutlet weak var userImage: UIImageView! {
        didSet {
            self.userImage.loadImage(Auth.auth().currentUser?.photoURL?.absoluteString)
            self.userImage.layer.cornerRadius
            = self.userImage.frame.height / 2
        }
    }
    @IBOutlet weak var userName: UILabel! {
        didSet {
            self.userName.text = Auth.auth().currentUser?.displayName
        }
    }
    
    @IBOutlet weak var articleTableView: UITableView! {
        didSet {
            self.articleTableView.delegate = self
            self.articleTableView.dataSource = self
        }
    }
    
    var photoCollectionView: UICollectionView!
    
    var viewModel = ArticleViewModel()
    
    var indexPath: IndexPath!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? FilterViewController,
           let cell = self.photoCollectionView.cellForItem(at: self.indexPath) as? PhotoCollectionViewCell {
            destination.image = cell.photoImageView.image
            
            return
        }
    }
    
    @IBAction func doAddArticle(_ sender: UIButton) {
        let waitingHud = JGProgressHUD(style: .dark)
        waitingHud.textLabel.text = "請稍候"

        if self.doCheckHasDog() {
            waitingHud.show(in: self.view)

            let articles = Firestore.firestore().collection("articles")
            let document: DocumentReference!
            
            if self.viewModel.model.id != "" {
                document = articles.document(self.viewModel.model.id)
            } else {
                document = articles.document()
            }
            
            let currentUser = Auth.auth().currentUser
            
            let storage = Storage.storage()
            let storageRef = storage.reference()
            var mediaURLs = [String]()
            
            let group = DispatchGroup()
            
            for mediaInfo in self.viewModel.model.medias {
                if let media = mediaInfo.media as? UIImage {
                    guard let imageData = media.jpegData(compressionQuality: 1) else { return }
                    let imageName = UUID().uuidString + ".jpg"
                    let imageRef = storageRef.child(imageName)
                    
                    group.enter()
                    
                    let uploadTask = imageRef.putData(imageData, metadata: nil) { metadata, error in
                        guard let metadata = metadata else {
                            print("上傳失敗：\(error?.localizedDescription ?? "")")
                            return
                        }
                        
                        guard let imagePath = metadata.path else {
                            print("無法取得圖片的絕對路徑")
                            return
                        }
                        
                        storageRef.child(imagePath).downloadURL { (url, error) in
                            defer {
                                // 離開 Dispatch Group
                                group.leave()
                            }
                            
                            if let error = error {
                                print(error)
                                return
                            }
                            
                            if let downloadURL = url {
                                mediaURLs.append(downloadURL.absoluteString)
                            }
                        }
                    }
                    
                    uploadTask.observe(.progress) { snapshot in
                        guard let progress = snapshot.progress else { return }
                        let percentComplete = 100.0 * Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
                        
                        print("上傳進度：\(percentComplete)%")
                    }
                }
            }
            
            // 等待所有上傳完成
            group.notify(queue: .main) { [weak self] in
                let data: [String: Any] = [
                    "createTime": Date().timeIntervalSince1970,
                    "authorId": currentUser!.uid as Any,
                    "authorName": currentUser!.displayName as Any,
                    "content": self?.viewModel.model.content as Any,
                    "hashtags": self?.viewModel.model.hashTags as Any,
                    "medias": mediaURLs.map { url in return [
                        "type": "photo",
                        "media": url
                    ] }
                ]
                
                document.setData(data) { [weak self] error in
                    if let error = error {
                        print(error)
                    } else {
                        waitingHud.dismiss(animated: true)
                        
                        self?.navigationController?.popToRootViewController(animated: true)
                    }
                }
            }
        } else {
            let hud = JGProgressHUD()
            hud.indicatorView = JGProgressHUDErrorIndicatorView()
            hud.textLabel.text = "發文照片請至少出現一位狗狗"
            hud.show(in: self.view)
            hud.dismiss(afterDelay: 1.5)
            waitingHud.dismiss(animated: true)
        }
    }
    
    private func doCheckHasDog() -> Bool {
        var hasDog = false
        
        let request = VNCoreMLRequest(model: model) { request, error in
            guard let results = request.results as? [VNRecognizedObjectObservation] else {
                print("辨識失敗：\(error?.localizedDescription ?? "")")
                return
            }
            
            let confidenceThreshold: Float = 0.2 // 設定信心閾值
            
            for result in results {
                for label in result.labels {
                    print(label.identifier, " ", label.confidence)
                }
                
                if result.labels.contains(where: { $0.identifier == "dog" && $0.confidence >= confidenceThreshold }) {
                    hasDog = true
                    
                    return
                }
            }
        }
        
        for mediaInfo in self.viewModel.model.medias {
            guard let media = mediaInfo.media as? UIImage else { return false }
            
            guard let ciImage = CIImage(image: media) else {
                print("無法建立 CIImage")
                return false
            }
            
            let imageRequestHandler = VNImageRequestHandler(ciImage: ciImage)
            
            do {
                try imageRequestHandler.perform([request])
            } catch {
                print("辨識失敗：\(error.localizedDescription)")
            }
        }
        
        return hasDog
    }
    
    @IBAction func unwindSegue(segue: UIStoryboardSegue) {
        let source = segue.source as? FilterViewController
        
        if self.indexPath == nil {
            self.viewModel.model.medias.append(
                MediaInfo(
                    type: "Photo",
                    media: source?.image as Any
                )
            )
        } else {
            self.viewModel.model.medias[self.indexPath.row].media = source?.image as Any
        }
        
        self.indexPath = nil
        self.photoCollectionView.reloadData()
    }
}

extension AddArticleViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "AddArticleTableViewCell", for: indexPath) as? AddArticleTableViewCell else { return UITableViewCell() }
        
        cell.photoCollectionView.dataSource = self
        cell.photoCollectionView.delegate = self
        
        cell.setContent = { [weak self] content in
            self?.viewModel.onContentChange(content: content)
        }
        
        cell.setHashtags = { [weak self] hashtags in
            self?.viewModel.onHashTagsChange(hashTags: hashtags)
        }
        
        cell.contentTextView.text = self.viewModel.model.content
        
        cell.setCell()
        
        self.photoCollectionView = cell.photoCollectionView
        
        return cell
    }
}

extension AddArticleViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.viewModel.model.medias.count + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.row == self.viewModel.model.medias.count {
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "AddPhotoCollectionViewCell",
                for: indexPath
            )
            
            return cell
        } else {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCollectionViewCell", for: indexPath) as? PhotoCollectionViewCell else {
                return UICollectionViewCell()
            }
            
            if let image = self.viewModel.model.medias[indexPath.row].media as? UIImage {
                cell.photoImageView.image = image
            }
            
            if let image = self.viewModel.model.medias[indexPath.row].media as? String {
                cell.photoImageView.loadImage(image)
            }
            
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.row == self.viewModel.model.medias.count {
            self.performSegue(withIdentifier: "ImagePick", sender: self)
        } else {
            self.indexPath = indexPath
            
            self.performSegue(withIdentifier: "ImageFilter", sender: self)
        }
    }
}
