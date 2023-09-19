//
//  CameraViewController.swift
//  GoYo
//
//  Created by 方品中 on 2023/5/24.
//
import UIKit
import AVFoundation
import Photos

class CameraViewController: UIViewController {
    @IBOutlet weak var captureButton: UIButton! {
        didSet {
            self.captureButton.layer.cornerRadius = min(
                self.captureButton.frame.width,
                self.captureButton.frame.height
            ) / 2
        }
    }
    @IBOutlet weak var toggleCameraButton: UIButton!
    @IBOutlet weak var toggleFlashButton: UIButton!
    @IBOutlet weak var previewView: PreviewView!
    
    var captureSession: AVCaptureSession!
    var stillImageOutput = AVCapturePhotoOutput()
    var previewLayer: AVCaptureVideoPreviewLayer!
    var currentCamera: AVCaptureDevice!
    var frontCamera: AVCaptureDevice!
    var backCamera: AVCaptureDevice!
    var frontCameraInput: AVCaptureDeviceInput!
    var backCameraInput: AVCaptureDeviceInput!
    
    var flashMode = AVCaptureDevice.FlashMode.off
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.captureSession = AVCaptureSession()
        self.captureSession.sessionPreset = .photo
        
        guard let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            return
        }
        
        do {
            self.frontCamera = frontCamera
            self.backCamera = backCamera
            
            self.frontCameraInput = try AVCaptureDeviceInput(device: self.frontCamera)
            self.backCameraInput = try AVCaptureDeviceInput(device: self.backCamera)
            
            self.captureSession.addInput(self.backCameraInput)
            self.captureSession.addOutput(self.stillImageOutput)
            self.setupLivePreview()
            
            self.currentCamera = backCamera
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.navigationBar.isHidden = true
        self.captureButton.isEnabled = true
        
        if !self.captureSession.isRunning {
            DispatchQueue.global().async {
                self.captureSession.startRunning()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.navigationController?.navigationBar.isHidden = false
        self.captureButton.isEnabled = false
        
        if self.captureSession.isRunning {
            self.captureSession.stopRunning()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? FilterViewController,
           let image = sender as? UIImage {
            destination.image = image.fixOrientation()
        }
    }
    
    private func setupLivePreview() {
        self.previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
        self.previewLayer.videoGravity = .resizeAspectFill
        self.previewLayer.connection?.videoOrientation = .portrait
        self.previewLayer.frame = self.previewView.bounds
        self.previewView.layer.insertSublayer(self.previewLayer, at: 0)
    }
    
    private func flashScreen() {
        let flashView = UIView(frame: self.previewView.bounds)
        flashView.backgroundColor = UIColor.white
        flashView.alpha = 1.0
        
        self.previewView.addSubview(flashView)
        
        UIView.animate(withDuration: 0.2, animations: {
            flashView.alpha = 0.0
        }, completion: { _ in
            flashView.removeFromSuperview()
        })
    }
    
    @IBAction func takePhoto(_ sender: UIButton) {
        self.captureButton.isEnabled = false
        
        let settings = AVCapturePhotoSettings()
        settings.flashMode = self.flashMode
        
        self.stillImageOutput.capturePhoto(with: settings, delegate: self)
        
        self.flashScreen()
    }
    
    @IBAction func switchCamera(_ sender: UIButton) {
        captureSession.beginConfiguration()
        
        guard let currentInput = captureSession.inputs.first as? AVCaptureDeviceInput else { return }
        self.captureSession.removeInput(currentInput)
        
        if self.currentCamera == self.backCamera {
            self.captureSession.addInput(self.frontCameraInput)
            self.currentCamera = self.frontCamera
        } else {
            self.captureSession.addInput(self.backCameraInput)
            self.currentCamera = self.backCamera
        }
        
        captureSession.commitConfiguration()
    }
    
    @IBAction func toggleFlash(_ sender: UIButton) {
        guard currentCamera.hasFlash else { return }
        
        switch self.flashMode {
        case .off:
            self.flashMode = .on
            self.toggleFlashButton.setImage(#imageLiteral(resourceName: "closeFlash"), for: .normal)
        case .on:
            self.flashMode = .off
            self.toggleFlashButton.setImage(#imageLiteral(resourceName: "flash"), for: .normal)
        default:
            break
        }
    }
}

extension CameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation() else {
            return
        }
        
        if let image = UIImage(data: imageData) {
            self.performSegue(withIdentifier: "ImageFilter", sender: image)
        }
    }
}
