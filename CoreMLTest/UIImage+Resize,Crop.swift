//
//  UIImage+Resize,Crop.swift
//  CoreMLTest
//
//  Created by Supphawit Getmark on 27/3/2561 BE.
//  Copyright © 2561 Supphawit Getmark. All rights reserved.
//

import Foundation
import UIKit

extension UIImage {
    
    func resizeImage(targetSize: CGSize) -> UIImage {
        
        let rect = CGRect(x: 0, y: 0, width: targetSize.width, height: targetSize.height)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 1.0)
        self.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
    
    /// ref from https://stackoverflow.com/questions/158914/cropping-an-uiimage comment that talk about swift 3 resize and modified by change cgimage to ciimage because our UIImage is made by CIImage
    ///
    /// - Parameters:
    ///   - imageToCrop: original image
    ///   - rect: destination of crop rectangle
    /// - Returns: new UIImage that already cropped.
    func cropImage(toRect rect:CGRect) -> UIImage{
        UIGraphicsBeginImageContextWithOptions(rect.size, false, self.scale)
        self.draw(at: CGPoint(x: -rect.origin.x, y: -rect.origin.y))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
}
