//
//  ViewController.swift
//  CoreMLTest
//
//  Created by Supphawit Getmark on 7/30/2560 BE.
//  Copyright © 2560 Supphawit Getmark. All rights reserved.
//

import UIKit
import CoreML

@available(iOS 11.0, *)
class ViewController: UIViewController, CameraControllerDelegate {
    
    //MARK:- Propreties
    let cameraController = CameraController()
    var isProcessing = false
    let gazeLogic: EyeGazeLogic = EyeGazeLogic()
    
    let generateRandomCircle = false
    
    var circleDrawTimer: Timer?
    
    //MARK:- ViewAction
    override func viewDidLoad() {
        print(UIScreen.main.bounds)
        cameraController.prepare(completionHandler: {(error) in
            if let error = error{
                print(error)
            }
        })
        cameraController.delegate = self
        if(generateRandomCircle){
            circleDrawTimer = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(drawCircle), userInfo: nil, repeats: true)
        }

    }
    
    @objc func drawCircle(){
        let circlePath = UIBezierPath(arcCenter: CGPoint(x: Double(exactly:arc4random_uniform(100) )!, y: Double(exactly:arc4random_uniform(100) )!)
            , radius: CGFloat(20)
            , startAngle: CGFloat(0)
            , endAngle: CGFloat(Double.pi*2)
            , clockwise: true)
        let shapelayer = CAShapeLayer()
        shapelayer.path = circlePath.cgPath
        
        shapelayer.fillColor = UIColor.clear.cgColor
        shapelayer.strokeColor = UIColor.red.cgColor
        shapelayer.lineWidth = 3.0
        self.view.layer.sublayers?.removeAll()
        self.view.layer.addSublayer(shapelayer)
        
    }
    
    //MARK:- DelegateMethod
    func didCaptureVideoFrame(image: CIImage) {
        if(!isProcessing){
            DispatchQueue.global(qos: .background).async {
                self.isProcessing = true
                self.gazeLogic.detectEye(on: image)
                self.isProcessing = false
            }
        }
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

