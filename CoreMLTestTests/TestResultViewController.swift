//
//  TestResultViewController.swift
//  CoreMLTestTests
//
//  Created by Supphawit Getmark on 2/10/2560 BE.
//  Copyright © 2560 Supphawit Getmark. All rights reserved.
//

import XCTest

class TestResultViewController: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testConvertToCSVString() {
        var predictResult: [DotPosition: [PredictPoint]] = [:]
        let dotPosition: DotPosition = DotPosition(x: 1, y: 1)
        predictResult[dotPosition] = []
        predictResult[dotPosition]?.append(PredictPoint(posX: 1, posY: 1))
        let resultViewController: ShowResultViewController = ShowResultViewController()
        let singlePointResult = resultViewController.createCsvFrom(result: predictResult)
        XCTAssertEqual("1,1\n1.0, 1.0,183.397435897436,-115.579144641999\n", singlePointResult)
        for i in 2...5{
            let dotPosition: DotPosition = DotPosition(x: UInt32(i), y: UInt32(i))
            predictResult[dotPosition] = []
            for j in 2...5{
                predictResult[dotPosition]?.append(PredictPoint(posX: Double(j), posY: Double(j)))
            }
        }
        let multiPointResult = resultViewController.createCsvFrom(result: predictResult)
        XCTAssertEqual("""
1,1
1.0, 1.0,183.397435897436,-115.579144641999
3,3
2.0, 2.0,247.5,-179.682940893801
3.0, 3.0,311.602564102564,-243.786737145603
4.0, 4.0,375.705128205128,-307.890533397405
5.0, 5.0,439.807692307692,-371.994329649207
2,2
2.0, 2.0,247.5,-179.682940893801
3.0, 3.0,311.602564102564,-243.786737145603
4.0, 4.0,375.705128205128,-307.890533397405
5.0, 5.0,439.807692307692,-371.994329649207
4,4
2.0, 2.0,247.5,-179.682940893801
3.0, 3.0,311.602564102564,-243.786737145603
4.0, 4.0,375.705128205128,-307.890533397405
5.0, 5.0,439.807692307692,-371.994329649207
5,5
2.0, 2.0,247.5,-179.682940893801
3.0, 3.0,311.602564102564,-243.786737145603
4.0, 4.0,375.705128205128,-307.890533397405
5.0, 5.0,439.807692307692,-371.994329649207

""", multiPointResult)
    }
    
}
