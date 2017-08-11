//
//  TestLoadMeanFile.swift
//  CoreMLTestTests
//
//  Created by Supphawit Getmark on 8/11/2560 BE.
//  Copyright © 2560 Supphawit Getmark. All rights reserved.
//

import XCTest
import CoreML

class MeanLoader{
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
    
    func meanTextToArray(text: String) -> MLMultiArray?{
        let textArray = text.components(separatedBy: "\n")
        do{
            let array: MLMultiArray = try MLMultiArray(shape: [1, 3, 224, 224], dataType: .double)
            var index = 0
            for line in 0..<textArray.count{
                if line != 0 && line != 225 && line != 450{
                    for column in textArray[line].components(separatedBy: " "){
                        if column.trimmingCharacters(in: .whitespaces) != ""{
                            guard let temp = Double(column) else {
                                print(textArray[line])
                                return nil
                            }
                            array[index] = NSNumber(value: temp)
                            index += 1
                        }
                    }
                }
            }
        }
        catch{
            return nil
        }
       
        return nil
    }
}

class TestLoadMeanFile: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        let meanLoader: MeanLoader = MeanLoader()
        let faceMeanArray = meanLoader.loadMean(file: "facemean")
        let leftMeanArray = meanLoader.loadMean(file: "leftmean")
        let rightMeanArray = meanLoader.loadMean(file: "rightmean")
//        meanLoader.meanTextToArray(text: faceMeanArray!)
//        meanLoader.meanTextToArray(text: leftMeanArray!)
//        meanLoader.meanTextToArray(text: rightMeanArray!)
        XCTAssert(faceMeanArray != nil)
        XCTAssert(leftMeanArray != nil)
        XCTAssert(rightMeanArray != nil)
        //XCTAssert(mlarray.shape == [1, 3, 224, 224])
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
}
