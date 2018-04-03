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
import Vision

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
    
    func convertCoords(deviceName: String, labelOrientation: Int, labelActiveScreenW: Int, labelActiveScreenH: Int, useCM: Bool) -> CGPoint {
        
        // First, convert input to millimeters to be compatible with AppleDeviceData.mat
        var xOut:Float = Float(self.posX * 10)
        var yOut:Float = Float(self.posY * 10)
        let deviceNames = ["iPhone 6s Plus", "iPhone 6s", "iPhone 6 Plus", "iPhone 6", "iPhone 5s", "iPhone 5c", "iPhone 5", "iPhone 4s", "iPad Mini", "iPad Air 2", "iPad Air", "iPad 4", "iPad 3", "iPad 2"]
        
        let deviceCameraToScreenXMm = [23.5400, 18.6100, 23.5400, 18.6100, 25.8500, 25.8500, 25.8500, 14.9600, 60.7000, 76.8600, 74.4000, 74.5000, 74.5000, 74.5000]
        let deviceCameraToScreenYMm = [8.6600, 8.0400, 8.6500, 8.0300, 10.6500, 10.6400, 10.6500, 9.7800, 8.7000, 7.3700, 9.9000, 10.5000, 10.5000, 10.5000]
        
        let deviceScreenWidthMm = [68.3600, 58.4900, 68.3600, 58.5000, 51.7000, 51.7000, 51.7000, 49.9200, 121.3000, 153.7100, 149.0000, 149.0000,149.0000, 149.0000]
        let deviceScreenHeightMm = [121.5400, 104.0500, 121.5400, 104.0500, 90.3900, 90.3900, 90.3900, 74.8800, 161.2000, 203.1100, 198.1000, 198.1000, 198.1000, 198.1000]
        
        var index = -1
        
        for i in 0..<deviceNames.count {
            if deviceNames[i] == deviceName {
                index = i
                break
            }
        }
        if index == -1 {
            return CGPoint()
        }
        let dx = deviceCameraToScreenXMm[index]
        let dy = deviceCameraToScreenYMm[index]
        let dw = deviceScreenWidthMm[index]
        let dh = deviceScreenHeightMm[index]
        
        if labelOrientation == 1 {
            xOut = xOut + Float(dx)
            yOut = (-1)*(yOut) - Float(dy)
        } else if labelOrientation == 2 {
            xOut = xOut - Float(dx) + Float(dw)
            yOut = (-1)*(yOut) + Float(dy) + Float(dh)
        } else if labelOrientation == 3 {
            xOut = xOut - Float(dy)
            yOut = (-1)*(yOut) - Float(dx) + Float(dw)
        } else if labelOrientation == 4 {
            xOut = xOut + Float(dy) + Float(dh)
            yOut = (-1)*(yOut) + Float(dx)
        }
        
        if !useCM {
            if (labelOrientation == 1 || labelOrientation == 2) {
                xOut = (xOut * Float(labelActiveScreenW)) / Float(dw)
                yOut = (yOut * Float(labelActiveScreenH)) / Float(dh)
            } else if (labelOrientation == 3 || labelOrientation == 4) {
                xOut = (xOut * Float(labelActiveScreenW)) / Float(dh)
                yOut = (yOut * Float(labelActiveScreenH)) / Float(dw)
            }
        }
        
        if useCM {
            xOut = xOut / 10;
            yOut = yOut / 10;
        }
        
        return CGPoint(x: Double(xOut), y: Double(yOut))
    }
}



@available(iOS 11.0, *)
class EyeGazeLogic: EyeGazeLogicProtocol{
    
    //MARK:- Propreties
    let itrackerModel:MyModel = MyModel()
    
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
                print(faceScaleImage.extent)
                print(rightEyeImage.extent)
                print(leftEyeImage.extent)
                do{
                    guard let facePixelBuffer = toPixelBuffer(image: faceScaleImage) else {
                        throw PreprocessError.faceImageError
                    }
                    guard let leftEyePixelBuffer = toPixelBuffer(image: leftEyeImage) else {
                        throw PreprocessError.leftEyeError
                    }
                    guard let rightEyePixelBuffer = toPixelBuffer(image: rightEyeImage) else {
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
    
    //MARK:- convert Method
    func toPixelBuffer(image: CIImage) -> CVPixelBuffer? {
        var pixelBuffer: CVPixelBuffer? = nil
        let status = CVPixelBufferCreate(kCFAllocatorDefault, 224, 224, kCVPixelFormatType_32BGRA, nil, &pixelBuffer)
        if (status == kCVReturnSuccess){
            guard let _pixelBuffer = pixelBuffer else { fatalError() }
            CVPixelBufferLockBaseAddress(_pixelBuffer, CVPixelBufferLockFlags.init(rawValue: 0))
            let ciContext = CIContext()
//            ciContext.render(image
//                , to: _pixelBuffer
//                , bounds: CGRect.init(x: image.extent.origin.x
//                , y: image.extent.origin.y, width: 224, height: 224)
//                , colorSpace: CGColorSpaceCreateDeviceRGB())
            let cgImage = ciContext.createCGImage(image, from: image.extent)
            let data = CVPixelBufferGetBaseAddress(pixelBuffer!)
            let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
            let bitmapInfo = CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue)
            let context = CGContext(data: data, width: Int(224), height: Int(224), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: bitmapInfo.rawValue)
            
            context?.draw(cgImage!, in: CGRect(x: 0, y: 0, width: 224, height: 224))
            CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags.init(rawValue: 0))
            return pixelBuffer!
        }
        else{
            print("convert fail")
        }
        return nil
    }
    
    //MARK:- Preprocess Method
    func getEyeImageRect(posX: CGFloat, posY: CGFloat, size: CGFloat) -> CGRect{
        let eyeRect = CGRect(x: posX+size/2, y: posY+size/2, width: -size, height: -size)
        return eyeRect
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
