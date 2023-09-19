//
//  CIImage+Extension.swift
//  GoYo
//
//  Created by 方品中 on 2023/5/24.
//
import UIKit

extension CIImage {
    func toUIImage() -> UIImage {
        /*
            If need to reduce the process time, than use next code.
            But ot produce a bug with wrong filling in the simulator.
            return UIImage(ciImage: self)
         */
        let context: CIContext = CIContext.init(options: nil)
        let cgImage: CGImage = context.createCGImage(self, from: self.extent)!
        let image: UIImage = UIImage(cgImage: cgImage)
        return image
    }
    
    func toCGImage() -> CGImage? {
        let context = CIContext(options: nil)
        if let cgImage = context.createCGImage(self, from: self.extent) {
            return cgImage
        }
        return nil
    }
}
