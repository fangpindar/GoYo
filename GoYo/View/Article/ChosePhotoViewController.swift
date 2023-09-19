//
//  ChosePhotoViewController.swift
//  GoYo
//
//  Created by 方品中 on 2023/5/26.
//
import UIKit
import Photos

class ChosePhotoViewController: UIViewController {
    @IBOutlet weak var chosePhotoCollectionView: UICollectionView! {
        didSet {
            self.chosePhotoCollectionView.delegate = self
            self.chosePhotoCollectionView.dataSource = self
        }
    }
    
    var indexPath: IndexPath!
    
    var allPhotos = [UIImage]()
    
    var photos: PHFetchResult<PHAsset>?
    
    var selectedImage: UIImage!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        PHPhotoLibrary.requestAuthorization { [weak self] status in
            switch status {
            case .authorized:
                DispatchQueue.main.async {
                    self?.loadPhotos()
                }
                
            case .denied, .restricted:
                break
                
            case .notDetermined:
                break
            case .limited:
                break
            @unknown default:
                break
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? FilterViewController {
            destination.image = self.selectedImage
        }
    }
    
    private func loadPhotos() {
        let fetchOptions = PHFetchOptions()
        
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        self.photos = PHAsset.fetchAssets(with: fetchOptions)
        
        self.photos!.enumerateObjects { (asset, _, _) in
            let imageManager = PHImageManager.default()
            let targetSize = CGSize(width: 100, height: 100)
            let options = PHImageRequestOptions()
            options.isSynchronous = true
            
            imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFit, options: options) { (image, _) in
                if let image = image {
                    self.allPhotos.append(image)
                }
            }
        }
        
        self.chosePhotoCollectionView.reloadData()
    }
}

extension ChosePhotoViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let size = (self.view.frame.width - ( 16 * 2 ) - 4 ) / 4
        
        return CGSize(width: size, height: size)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.allPhotos.count + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.row == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TakePhotoCollectionViewCell", for: indexPath)
            
            return cell
        } else {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCollectionViewCell", for: indexPath) as? PhotoCollectionViewCell else {
                return UICollectionViewCell()
            }
            
            cell.photoImageView.image = self.allPhotos[indexPath.row - 1]
            
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            self.performSegue(withIdentifier: "TakePhoto", sender: self)
        } else {
            self.indexPath = indexPath
            
            let asset = self.photos![indexPath.row - 1]
            let imageManager = PHImageManager.default()
            let targetSize = CGSize(width: 500, height: 500)
            let options = PHImageRequestOptions()
            options.isSynchronous = true
            
            imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFit, options: options) { (image, _) in
                if let image = image {
                    self.selectedImage = image
                }
            }
            
            self.performSegue(withIdentifier: "ImageFilter", sender: self)
        }
    }
}
