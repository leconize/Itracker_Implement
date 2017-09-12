//
//  EyeGazeLogin.swift
//  CoreMLTest
//
//  Created by Supphawit Getmark on 8/23/2560 BE.
//  Copyright © 2560 Supphawit Getmark. All rights reserved.
//

import Foundation
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
    
    let posX: NSNumber;
    let posY: NSNumber;
}

@available(iOS 11.0, *)
class EyeGazeLogic: EyeGazeLogicProtocol{
    
    //MARK:- Propreties
    let itrackerModel:Itracker = Itracker()
    
    //MARK:- Protocol Method
    func detectEye(on image: CIImage) throws -> PredictPoint?{
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
                    guard let facePixelBuffer = faceScaleImage.pixelBuffer else {
                        print("face")
                        throw PreprocessError.faceImageError
                    }
                    guard let leftEyePixelBuffer = leftEyeImage.pixelBuffer else {
                        print("left")
                        throw PreprocessError.leftEyeError
                    }
                    guard let rightEyePixelBuffer = rightEyeImage.pixelBuffer else {
                        print("right")
                        throw PreprocessError.rightEyeError
                    }
                    let result = try itrackerModel.prediction(facegrid: facegrid
                        , image_face: facePixelBuffer
                        , image_left: leftEyePixelBuffer
                        , image_right: rightEyePixelBuffer)
                    print("result = ")
                    for index in 0...5{
                        print(result.fc3[index])
                    }
                    let predictPoint = PredictPoint(posX: result.fc3[0], posY: result.fc3[1])
                    return predictPoint
                    
                }
                catch{
                    
                    return nil
                }
            }
        }
        return nil
    }
    
    //MARK:- Preprocess Method
    func getEyeImageRect(posX: CGFloat, posY: CGFloat, size: CGFloat) -> CGRect{
        let reg = CGRect(x: posX+size/2, y: posY+size/2, width: -size, height: -size)
        return reg
    }
    
    func calculateFaceGrid(imageBound: CGRect, gridSize:CGFloat, faceBound:CGRect) -> MLMultiArray?{
        let scaleX = imageBound.width / gridSize
        let scaleY = imageBound.height / gridSize
        
        guard let faceGridArray = try? MLMultiArray(shape: [625,1, 1], dataType: .double) else{
            return nil
        }
        
        var xLow = faceBound.origin.x * scaleX
        var yLow = faceBound.origin.y * scaleY
        
        let width = faceBound.size.width * scaleX
        let height = faceBound.size.height * scaleY
        
        var xHi = xLow + width - 1
        var yHi = yLow + height - 1
        
        xLow = min(gridSize, max(1, xLow))
        xHi = min(gridSize, max(1, xHi))
        yLow = min(gridSize, max(1, yLow))
        yHi = min(gridSize, max(1, yHi))
        
        for index in 0..<(Int(gridSize*gridSize)){
            let row = round( CGFloat(index) / gridSize)
            let column = CGFloat(index%Int(gridSize))
            if(row <= xHi && row >= xLow && column <= yHi && column >= yLow){
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
