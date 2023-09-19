//
//  FilterViewController.swift
//  GoYo
//
//  Created by 方品中 on 2023/5/24.
//
import UIKit
import AVFoundation

class FilterViewController: UIViewController, UIScrollViewDelegate {
    var image: UIImage?
    
    @IBOutlet weak var imageFilterCollectionView: UICollectionView! {
        didSet {
            self.imageFilterCollectionView.delegate = self
            self.imageFilterCollectionView.dataSource = self
        }
    }
    
    @IBOutlet weak var imageView: UIImageView! {
        didSet {
            let scale = imageScrollView.frame.size.width / (self.image?.size.width)!
            let scaleImage = self.image?.scaleImage(scaleSize: scale)
            self.imageView.image = scaleImage
        }
    }
    
    @IBOutlet weak var imageScrollView: UIScrollView!

    override func viewDidLoad() {
        super.viewDidLoad()
        let zoomScale = (self.imageView.image?.size.height)! / self.imageScrollView.frame.height
        
        imageScrollView.minimumZoomScale = zoomScale
        imageScrollView.maximumZoomScale = 5.0
        imageScrollView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        imageScrollView.zoomScale = imageScrollView.minimumZoomScale
    }
    
    @IBAction func doConfirm(_ sender: UIBarButtonItem) {
        self.image = self.imageScrollView.snapshotVisibleArea

        self.performSegue(withIdentifier: "unwindSegue", sender: self)
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imageView
    }
}

extension FilterViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return CustomFilter.filters.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "FilterCollectionViewCell",
            for: indexPath
        ) as? FilterCollectionViewCell else {
            return UICollectionViewCell()
        }
        
        let filter = CustomFilter.filters[indexPath.row]
        
        cell.filterLabel.text = filter.name
        
        guard let originImage = self.image else { return cell }
        
        if let applier = filter.applier,
           let originCiImage = originImage.toCIImage(),
           let filterCiImage = applier(originCiImage) {
            cell.imageView.image = filterCiImage.toUIImage()
        } else {
            cell.imageView.image = originImage
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? FilterCollectionViewCell {
            self.imageView.image = cell.imageView.image
        }
    }
}

extension UIScrollView {
    var snapshotVisibleArea: UIImage? {
        UIGraphicsBeginImageContext(bounds.size)
        UIGraphicsGetCurrentContext()?.translateBy(x: -contentOffset.x, y: -contentOffset.y)
        layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}
