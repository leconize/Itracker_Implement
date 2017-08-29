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


@available(iOS 11.0, *)
class EyeGazeLogic{
    
    //MARK:- Propreties
    
    
    let ciContext: CIContext = CIContext()
    var pixelData = [UInt8](repeating: 0, count: 200704)
    let mlModel: TestModel = TestModel()
    let cgContext: CGContext;
    var faceMean: MeanValues
    var leftEyeMean: MeanValues
    var rightEyeMean: MeanValues
    
    
    
    
    //MARK:- ClassSetup
    init() {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        self.cgContext = CGContext(data: &pixelData, width: 224, height: 224, bitsPerComponent: 8, bytesPerRow: 4 * 224, space: colorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
        faceMean = MeanValues(filename: "facemean")
        leftEyeMean = MeanValues(filename: "leftmean")
        rightEyeMean = MeanValues(filename: "rightmean")
    }
    
    //MARK:- Setup Mean
    func loadMean(file filename:String) -> String?{
        do {
            if let path = Bundle.main.path(forResource: filename, ofType: "txt"){
                let data = try String(contentsOfFile:path, encoding: String.Encoding.utf8)
                return data
            }
        }
        catch{
            return nil
        }
        return nil
    }
    
    func meanTextToArray(text: String) -> [Double]?{
        let textArray = text.components(separatedBy: "\n")
        var array: [Double] = [Double](repeatElement(0, count: 150528))
        var index = 0
        for line in 0..<textArray.count{
            if line != 0 && line != 225 && line != 450{
                for column in textArray[line].components(separatedBy: " "){
                    if column.trimmingCharacters(in: .whitespaces) != ""{
                        guard let temp = Double(column) else {
                            print(textArray[line])
                            return nil
                        }
                        array[index] = temp
                        index += 1
                    }
                }
            }
        }
        return array
    }
    
    // MARK:- Detector
    func detectEye(on image: CIImage){
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
                let sendImage = image.cropped(to: face.bounds)
                
                let leftEyeImage = image.cropped(to: getEyeImageRect(posX: face.leftEyePosition.x, posY: face.leftEyePosition.y, size: 224))
                let rightEyeImage = image.cropped(to: getEyeImageRect(posX: face.rightEyePosition.x, posY: face.rightEyePosition.y, size: 224))
                
                let scale = 224 / sendImage.extent.size.width
                let faceScaleImage = scaleImage(sendImage, scale: Float(scale))
                
                print("image = \(faceScaleImage)")
                print("leftEye = \(leftEyeImage)")
                print("rightEye = \(rightEyeImage)")
                
                let facegrid = calculateFaceGrid(imageBound: image.extent, gridSize: 25, faceBound: face.bounds)
                
                let faceArray = preprocess(image: faceScaleImage, meanArray: faceMean)
                let leftEyeArray = preprocess(image: leftEyeImage, meanArray: leftEyeMean)
                let rightEyeArray = preprocess(image: rightEyeImage, meanArray: rightEyeMean)
                
                do{
                    let start = DispatchTime.now()
                    let result = try mlModel.prediction(facegrid: facegrid!, image_face: faceArray!, image_left: leftEyeArray!, image_right: rightEyeArray!)
                    print("result = ")
                    for index in 0...5{
                        print(result.fc3[index])
                    }
                    let end = DispatchTime.now()
                    let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds // <<<<< Difference in nano seconds (UInt64)
                    let timeInterval = Double(nanoTime) / 1_000_000_000 // Technically could overflow for long running tests
                    
                    print("Time to evaluate problem : \(timeInterval) seconds")
                }
                catch{
                    print("error haha")
                }
            }
        }
    }
    
    //MARK:- Preprocess Data
    func preprocess(image: CIImage, meanArray:MeanValues) -> MLMultiArray?{
        // MARK:- RGB check
        func isRed(index:Int) -> Bool{
            return (index % 4 == 0)
        }
        func isGreen(index:Int) -> Bool{
            return (index%4 == 1)
        }
        func isBlue(index:Int) -> Bool{
            return (index % 4 == 2)
        }
    
        guard let pixels = gereratePixelData(image: image) else {
            return nil }
        let start = DispatchTime.now()
        guard let array = try? MLMultiArray(shape: [3, 224, 224], dataType: .double) else {
            return nil
        }
        //        50176
        //        0,4, 8, 12, 16 -> 0,1,2,3,4,5,6 r
        //        1,5,9,13,17 -> 50176,50177, 50178, 50179 g
        //        2,6,10,14,18 -> 100352, 100353, 100354, 100355 b
        for i in 0..<150528{
            //bgr assign
            if isRed(index: i){
                array[i/4 + 100352] = (Double(exactly:pixels[i])! - meanArray.means[i/4 + 100352]) as NSNumber
            }
            else if isGreen(index: i){
                array[i/4 + 50176] = (Double(exactly:pixels[i])! - meanArray.means[i/4 + 50176]) as NSNumber
            }
            else if isBlue(index: i){
                array[i/4] = (Double(exactly:pixels[i])! - meanArray.means[i/4]) as NSNumber
            }
        }
        let end = DispatchTime.now()
        let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds // <<<<< Difference in nano seconds (UInt64)
        let timeInterval = Double(nanoTime) / 1_000_000_000 // Technically could overflow for long running tests
        print("aTime to evaluate problem : \(timeInterval) seconds")
        return array
    }
    
    //MARK:- Preprocess Implementation Detail
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
    
    func getEyeImageRect(posX: CGFloat, posY: CGFloat, size: CGFloat) -> CGRect{
        let reg = CGRect(x: posX+size/2, y: posY+size/2, width: -size, height: -size)
        return reg
    }
    
    func scaleImage(_ image: CIImage, scale:Float) -> CIImage{
        let filter = CIFilter(name: "CILanczosScaleTransform")!
        filter.setValue(image, forKey: "inputImage")
        filter.setValue(scale, forKey: "inputScale")
        filter.setValue(1.0, forKey: "inputAspectRatio")
        return filter.value(forKey: "outputImage") as! CIImage
    }
    
    func gereratePixelData(image:CIImage) -> [UInt8]?{
        guard let cgImage = ciContext.createCGImage(image, from: image.extent) else {
            return nil
        }
        cgContext.draw(cgImage, in: CGRect(x: 0, y: 0, width: image.extent.width, height: image.extent.height))
        return self.pixelData
    }
}
