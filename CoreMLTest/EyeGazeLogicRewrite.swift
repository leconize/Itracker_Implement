//
//  EyeGazeLogicRewrite.swift
//  CoreMLTest
//
//  Created by Supphawit Getmark on 25/3/2561 BE.
//  Copyright © 2561 Supphawit Getmark. All rights reserved.
//

import Foundation
import UIKit
import CoreML

class EyeGazeLogicRewrite: EyeGazeLogicProtocol {
    
    
    func detectEye(on image: CIImage) throws -> PredictPoint? {
//        let scaleFactorInverse = 224 / image.extent.width
        let accuracy = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        guard let faceDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: accuracy) else { throw PreprocessError.faceImageError }
        
        let faces = faceDetector.features(in: image)
        if faces.count > 0 {
            guard let faceFeature = faces[0] as? CIFaceFeature else {
                throw PreprocessError.faceImageError
            }
            if faceFeature.hasRightEyePosition && faceFeature.hasLeftEyePosition {
                let targetSize: CGSize = CGSize(width: 224, height: 224)
                let fullImage:UIImage = UIImage(ciImage: image)
                
                let cropface = fullImage.cropImage(toRect: faceFeature.bounds.rectWithFlippedY(inFrame: image.extent.size))
                let boxSize = image.extent.width * 0.2
                let boxSizeHalf = image.extent.width * 0.2 / 2
                print(faceFeature.leftEyePosition.x, faceFeature.leftEyePosition.y)
                print(faceFeature.rightEyePosition.x, faceFeature.rightEyePosition.y)
//                let leftEyeRect = CGRect(x: (faceFeature.leftEyePosition.x - boxSizeHalf) * scaleFactorInverse,
//                                         y: cropface.size.height-(faceFeature.leftEyePosition.y - boxSizeHalf) * scaleFactorInverse,
//                                         width: boxSize * scaleFactorInverse,
//                                         height: boxSize * scaleFactorInverse)
//                let rightEyeRect = CGRect(x: (faceFeature.rightEyePosition.x - boxSizeHalf) * scaleFactorInverse,
//                                         y: (faceFeature.rightEyePosition.y - boxSizeHalf) * scaleFactorInverse,
//                                         width: boxSize * scaleFactorInverse,
//                                         height: boxSize * scaleFactorInverse)
                
                
                let leftEyeRect = CGRect(x: (faceFeature.leftEyePosition.x - boxSizeHalf) ,
                                         y: (fullImage.size.height-faceFeature.leftEyePosition.y - boxSizeHalf) ,
                                         width: boxSize ,
                                         height: boxSize)
                let rightEyeRect = CGRect(x: (faceFeature.rightEyePosition.x - boxSizeHalf),
                                          y: (fullImage.size.height-faceFeature.rightEyePosition.y - boxSizeHalf),
                                          width: boxSize,
                                          height: boxSize)
               
                let leftEyeImage =  fullImage.cropImage(toRect: leftEyeRect).resizeImage(targetSize: targetSize)
                let rightEyeImage =  fullImage.cropImage(toRect: rightEyeRect).resizeImage(targetSize: targetSize)
                
                guard let facegrid = createFaceGrid(frameW: Double(image.extent.width),
                               frameH: Double(image.extent.height),
                               gridW: 25, gridH: 25,
                               labelFaceX: Double(faceFeature.bounds.origin.x), labelFaceY: Double(faceFeature.bounds.origin.y),
                               labelFaceW: Double(faceFeature.bounds.width), labelFaceH: Double(faceFeature.bounds.height))
                    else {
                        return nil
                }
                guard let pixelFace = cropface.pixelBuffer(width: 224, height: 224) else {
                    return nil
                }
                guard let pixelLeftEyeImage = leftEyeImage.pixelBuffer(width: 224, height: 224) else {
                    return nil
                }
                guard let pixelRightEyeImage = rightEyeImage.pixelBuffer(width: 224, height: 224) else {
                    return nil
                }
                let model: MyModel = MyModel()
                guard let result = try? model.prediction(facegrid: facegrid, image_face: pixelFace, image_left: pixelLeftEyeImage, image_right: pixelRightEyeImage) else {
                    return nil
                }
                print(result.fc3[0])
                print(result.fc3[1])
                return PredictPoint(posX: Double(truncating: result.fc3[0]), posY: Double(truncating: result.fc3[1]))
            }
        }
        
        
        return PredictPoint(posX: 0, posY: 0)
    }
    
    
    // Adapted from Kyle's facerect2grid.m
    func createFaceGrid(frameW: Double, frameH: Double, gridW: Double, gridH: Double, labelFaceX: Double, labelFaceY: Double, labelFaceW: Double, labelFaceH: Double) -> MLMultiArray? {
        let scaleX = gridW / frameW
        let scaleY = gridH / frameH
        guard let flattenedGrid = try? MLMultiArray.init(shape: [625, 1, 1], dataType: .int32) else {
            return nil
        }
        
        // Use zero-based image coordinates.
        var xLo = Int(round(labelFaceX * scaleX))
        var yLo = Int(round(labelFaceY * scaleY))
        let w = Int(round(labelFaceW * scaleX))
        let h = Int(round(labelFaceH * scaleY))
        var xHi = xLo + w - 1
        var yHi = yLo + h - 1
        xLo = min(Int(round(gridW) - 1), max(0, xLo))
        xHi = min(Int(round(gridW) - 1), max(0, xHi))
        yLo = min(Int(round(gridH) - 1), max(0, yLo))
        yHi = min(Int(round(gridH) - 1), max(0, yHi))
        for i in 0..<25 {
            for j in 0..<25 {
                flattenedGrid[25 * i + j] = 0
            }
        }
        for i in yLo..<yHi {
            for j in xLo..<xHi {
                flattenedGrid[25 * i + j] = 1
            }
        }
        
        return flattenedGrid
    }


}
