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
    var gazeLogic: EyeGazeLogic?
    
    let generateRandomCircle = true
    var currentCircleX: UInt32?
    var currentCircleY: UInt32?
    let circleRadius: CGFloat = 20
    
    lazy var circleDrawTimer: Timer = Timer.init()
    
    //MARK:- ViewAction
    override func viewDidLoad() {
        cameraController.prepare(completionHandler: {(error) in
            if let error = error{
                print(error)
            }
        })
        DispatchQueue.global().async {
            self.gazeLogic = EyeGazeLogic()
            self.cameraController.delegate = self
        }
        
        if(generateRandomCircle){
            circleDrawTimer = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(drawCircle), userInfo: nil, repeats: true)
        }
    }
    
    @objc func drawCircle(){
        let screenRect = UIScreen.main.bounds
        self.currentCircleX = arc4random_uniform(UInt32(screenRect.width-circleRadius)) + UInt32(circleRadius)
        self.currentCircleY = arc4random_uniform(UInt32(screenRect.height-circleRadius)) + UInt32(circleRadius)
        let circlePath = UIBezierPath(
            arcCenter: CGPoint(x: Double(currentCircleX!)
            , y: Double(currentCircleY!))
            , radius: circleRadius
            , startAngle: CGFloat(0)
            , endAngle: CGFloat(Double.pi*2)
            , clockwise: true)
         
        let shapelayer = CAShapeLayer()
        shapelayer.path = circlePath.cgPath
        shapelayer.fillColor = UIColor.red.cgColor
        shapelayer.strokeColor = UIColor.red.cgColor
        shapelayer.lineWidth = 3.0
        guard let layerCount = view.layer.sublayers?.count else {
            return
        }
        if(layerCount == 3){
            self.view.layer.sublayers?.removeLast()
        }
        self.view.layer.addSublayer(shapelayer)
    }
    
    //MARK:- DelegateMethod
    func didCaptureVideoFrame(image: CIImage) {
        if(!isProcessing){
            DispatchQueue.global(qos: .userInteractive).async {
                do {
                    self.isProcessing = true
                    guard (try self.gazeLogic?.detectEye(on: image)) != nil else {
                        self.isProcessing = false
                        return
                    }
                    self.isProcessing = false
                }
                catch{
                    
                }
                
                
            }
        }
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

