//
//  TestPredictPointConvert.swift
//  CoreMLTestTests
//
//  Created by Supphawit Getmark on 9/20/2560 BE.
//  Copyright © 2560 Supphawit Getmark. All rights reserved.
//

import XCTest

class TestPredictPointConvert: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testConvertToScreenPoint() {
        let point: PredictPoint = PredictPoint(posX: 1.26, posY: -7.76)
        XCTAssertEqual(point.toScreenPoint().x, 200.0641)
        XCTAssertEqual(point.toScreenPoint().y, 445.9701)
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
