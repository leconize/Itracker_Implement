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
//        let point = PredictPoint(posX: 1.26, posY: -7.76).toScreenPoint()
//        -3.27383208  0.99026316
//        -1.73477387 -2.54712701
//        3.004611253738403
//        -9.196148872375488
        let point = PredictPoint(posX: 3.004611253738403, posY: 9.196148872375488).toScreenPoint()

        let forthPlacesDecimalX = String.init(format: "%.4f", point.x)
        let forthPlacesDecimalY = String.init(format: "%.4f", point.y)
        XCTAssertEqual(forthPlacesDecimalX, "\(200.0641)")
        XCTAssertEqual(forthPlacesDecimalY, "\(445.9701)")
        
        
        
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
}
