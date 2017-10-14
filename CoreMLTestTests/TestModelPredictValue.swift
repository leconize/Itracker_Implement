//
//  TestModelPredictValue.swift
//  CoreMLTestTests
//
//  Created by Supphawit Getmark on 12/10/2560 BE.
//  Copyright © 2560 Supphawit Getmark. All rights reserved.
//

import XCTest
import CoreML

class TestModelPredictValue: XCTestCase {
    
    let itracker: Itracker = Itracker()
    let eyeGazeLogic: EyeGazeLogic = EyeGazeLogic()
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func calculateFaceGrid(imageBound: CGRect, gridSize:CGFloat, faceBound:CGRect) -> MLMultiArray?{
        let scaleX = gridSize / imageBound.width
        let scaleY = gridSize / imageBound.height
        
        guard let faceGridArray = try? MLMultiArray(shape: [625,1, 1], dataType: .double) else{
            return nil
        }
//        abelFaceY = frameH-labelFaceY-labelFaceH
        
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
    
    
    
    func testExample() {
        let faceImage = CIImage(image: UIImage(named: "faceScaleImage")!)
        let leftEyeImage = CIImage(image: UIImage(named: "leftEyeImage")!)
        let rightEyeImage = CIImage(image: UIImage(named: "rightEyeImage")!)
        
        guard let facePixel = eyeGazeLogic.toCreataImage(image: faceImage!) else { return }
        guard let leftPixel = eyeGazeLogic.toCreataImage(image: leftEyeImage!) else { return }
        guard let rightPixel = eyeGazeLogic.toCreataImage(image: rightEyeImage!) else { return }
        
        let imageBound = CGRect(x: 0, y: 0, width: 720, height: 1280)
        let gridSize: CGFloat = 25
//        100, 127.5, 450, 450
        let faceBound: CGRect = CGRect(x: 100, y: 127.5, width: 450, height: 450)
        let faceGrid = calculateFaceGrid(imageBound: imageBound, gridSize: gridSize, faceBound: faceBound)
        for i in 0..<25{
            for j in 0..<25{
                print(faceGrid![i*25+j], separator: " ", terminator: " ")
            }
            print(" ")
        }
        do {
            try eyeGazeLogic.predict(faceGrid: faceGrid!, imageFace: facePixel, imageLeft: leftPixel, imageRight: rightPixel)
        } catch {
            print(error)
        }
        
    }
    
}
