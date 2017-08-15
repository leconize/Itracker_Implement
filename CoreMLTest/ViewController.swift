//
//  ViewController.swift
//  CoreMLTest
//
//  Created by Supphawit Getmark on 7/30/2560 BE.
//  Copyright © 2560 Supphawit Getmark. All rights reserved.
//

import UIKit
import CoreML

class ViewController: UIViewController {

    let myModel = TestModel()
    
    override func viewDidLoad() {
        let cameraController: CameraController = CameraController()
        cameraController.prepare(completionHandler: {(error) in
            print(error)
        })
        super.viewDidLoad()
        print(myModel.model.modelDescription)

        // Do any additional setup after loading the view, typically from a nil
    
//        guard let mlMultiArray1 = try? MLMultiArray(shape:[625,1, 1], dataType:MLMultiArrayDataType.double) else {
//            fatalError("Unexpected runtime error. MLMultiArray")
//        }
//        guard let mlMultiArray2 = try? MLMultiArray(shape:[3,224, 224], dataType:MLMultiArrayDataType.double) else {
//            fatalError("Unexpected runtime error. MLMultiArray")
//        }
//        guard let mlMultiArray3 = try? MLMultiArray(shape:[3,224, 224], dataType:MLMultiArrayDataType.double) else {
//            fatalError("Unexpected runtime error. MLMultiArray")
//        }
//        guard let mlMultiArray4 = try? MLMultiArray(shape:[3,224, 224], dataType:MLMultiArrayDataType.double) else {
//            fatalError("Unexpected runtime error. MLMultiArray")
//        }
//        guard let predict = try? myModel.prediction(facegrid: mlMultiArray1, image_face: mlMultiArray2, image_left: mlMultiArray3, image_right: mlMultiArray4) else {
//            fatalError("Unexpected runtime error. MLMultiArray")
//        }
//
//        print(mlMultiArray1[0])
//        let max = predict.fc3.count
//        print(max)
//        for index in 0...5{
//            print(predict.fc3[index])
//        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

