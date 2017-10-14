//
//  EyeGazeLogin.swift
//  CoreMLTest
//
//  Created by Supphawit Getmark on 8/23/2560 BE.
//  Copyright © 2560 Supphawit Getmark. All rights reserved.
//

import Foundation
import UIKit
import CoreImage
import CoreML

protocol EyeGazeLogicProtocol {
    func detectEye(on image:CIImage) throws -> PredictPoint?
}

enum PreprocessError: Error{
    case faceImageError
    case leftEyeError
    case rightEyeError
    case failToCreateFaceGrid
}

struct PredictPoint{
    
    var posX: Double;
    var posY: Double;
    
    func toScreenPoint() -> CGPoint{
        let dX = 18.61
        let dY = 8.03
        let dWidth = 58.5
        let dHeight = 104.05
        var x = posX*10
        var y = posY*10
        switch UIApplication.shared.statusBarOrientation {
        case .portrait:
            x += dX
            y = -y - dY
        case .portraitUpsideDown:
            x = x - dX + dWidth
            y = -y + dY + dHeight
        case .landscapeRight:
            x = x - dY
            y = -y - dX + dWidth
        case .landscapeLeft:
            x = y + dY + dHeight
            y = -y + dX
        case .unknown:
            print("unknown")
        }
        let screenWidth: Double = 375
        let screenHeight: Double = 667
        if(UIApplication.shared.statusBarOrientation.isPortrait){
            x = x * screenWidth / dWidth
            y = y * screenHeight / dHeight
        }
        else if(UIApplication.shared.statusBarOrientation.isLandscape){
            x = x * screenWidth / dHeight
            y = y * screenHeight / dWidth
        }
        return CGPoint(x: x, y: y)
    }
}



@available(iOS 11.0, *)
class EyeGazeLogic: EyeGazeLogicProtocol{
    
    //MARK:- Propreties
    let itrackerModel:Itracker = Itracker()
    let context: CIContext = CIContext()
    
    //MARK:- Protocol Method
    func detectEye(on image: CIImage) throws -> PredictPoint? {
        let accuracy = [CIDetectorAccuracy: CIDetectorAccuracyLow]
        let faceDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: accuracy)
        let faces = faceDetector?.features(in: image)
        for face in faces as! [CIFaceFeature] {
            if face.hasLeftEyePosition{
                print("Left eye bounds are \(face.leftEyePosition)")
            }
            if face.hasRightEyePosition{
                print("Right eye bounds are \(face.rightEyePosition)")
            }
            if face.hasRightEyePosition && face.hasLeftEyePosition{
                let faceImage = image.cropped(to: face.bounds)
                let scale = 224 / faceImage.extent.size.width
                let faceScaleImage = scaleImage(faceImage, scale: Float(scale))
                let leftEyeImage = image.cropped(to: getEyeImageRect(posX: face.leftEyePosition.x, posY: face.leftEyePosition.y, size: 224))
                let rightEyeImage = image.cropped(to: getEyeImageRect(posX: face.rightEyePosition.x, posY: face.rightEyePosition.y, size: 224))
                guard let facegrid = calculateFaceGrid(imageBound: image.extent, gridSize: 25, faceBound: face.bounds) else {
                    throw PreprocessError.failToCreateFaceGrid
                }
                do{
                    guard let facePixelBuffer = toCreataImage(image: faceScaleImage) else {
                        throw PreprocessError.faceImageError
                    }
                    guard let leftEyePixelBuffer = toCreataImage(image: leftEyeImage) else {
                        throw PreprocessError.leftEyeError
                    }
                    guard let rightEyePixelBuffer = toCreataImage(image: rightEyeImage) else {
                        throw PreprocessError.rightEyeError
                    }
                    return try predict(faceGrid: facegrid, imageFace: facePixelBuffer, imageLeft: leftEyePixelBuffer, imageRight: rightEyePixelBuffer)
                }
                catch{
                    return nil
                }
            }
        }
        return nil
    }
    
    func predict(faceGrid: MLMultiArray
        , imageFace:CVPixelBuffer
        , imageLeft:CVPixelBuffer
        , imageRight:CVPixelBuffer) throws -> PredictPoint {
            let result = try itrackerModel.prediction(facegrid: faceGrid
                , image_face: imageFace
                , image_left: imageLeft
                , image_right: imageRight)
            for index in 0...5{
                print(result.fc3[index])
            }
            let predictPoint = PredictPoint(
                posX: Double(truncating: result.fc3[0])
                , posY: Double(truncating: result.fc3[1]))
            return predictPoint
    }
    
    //MARK:- reposition
    func toCreataImage(image: CIImage) -> CVPixelBuffer? {
        var pixelBuffer: CVPixelBuffer? = nil
        let status = CVPixelBufferCreate(kCFAllocatorDefault, 224, 224, kCVPixelFormatType_32BGRA, nil, &pixelBuffer)
        if (status == kCVReturnSuccess) {
            let context = CIContext()
            context.render(image, to: pixelBuffer!, bounds: CGRect.init(x: 0, y: 0, width: 224, height: 224), colorSpace: CGColorSpaceCreateDeviceRGB())
            return pixelBuffer!
        }
        else{
            print("convert fail")
        }
        return nil
    }
    
    //MARK:- Preprocess Method
    func getEyeImageRect(posX: CGFloat, posY: CGFloat, size: CGFloat) -> CGRect{
        let reg = CGRect(x: posX+size/2, y: posY+size/2, width: -size, height: -size)
        return reg
    }
    
    
    func calculateFaceGrid(imageBound: CGRect, gridSize:CGFloat, faceBound:CGRect) -> MLMultiArray? {
        
        let scaleX = gridSize / imageBound.width
        let scaleY = gridSize / imageBound.height
        
        guard let faceGridArray = try? MLMultiArray(shape: [625,1, 1], dataType: .double) else {
            return nil
        }
        
        let calY = imageBound.height - faceBound.origin.y - faceBound.height
        
        var xLow = (faceBound.origin.x * scaleX).rounded() + 1
        var yLow = (calY * scaleY).rounded() + 1
        
        let width = (faceBound.size.width * scaleX).rounded()
        let height = (faceBound.size.height * scaleY).rounded()
        
        var xHi = xLow + width - 1
        var yHi = yLow + height - 1
        
        xLow = min(gridSize, max(1, xLow))
        xHi = min(gridSize, max(1, xHi))
        yLow = min(gridSize, max(1, yLow))
        yHi = min(gridSize, max(1, yHi))
        
        for index in 0..<(Int(gridSize*gridSize)){
            let row = floor(CGFloat(index) / gridSize)
            let column = CGFloat(index%Int(gridSize))
            if(row <= yHi - 1 && row >= yLow - 1 && column <= xHi - 1 && column >= xLow - 1){
                faceGridArray[index] = 1
            }
            else{
                faceGridArray[index] = 0
            }
        }
        return faceGridArray
    }
    
    func scaleImage(_ image: CIImage, scale:Float) -> CIImage{
        let filter = CIFilter(name: "CILanczosScaleTransform")!
        filter.setValue(image, forKey: "inputImage")
        filter.setValue(scale, forKey: "inputScale")
        filter.setValue(1.0, forKey: "inputAspectRatio")
        return filter.value(forKey: "outputImage") as! CIImage
    }
    
}
