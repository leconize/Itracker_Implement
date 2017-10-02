//
//  ViewController.swift
//  CoreMLTest
//
//  Created by Supphawit Getmark on 7/30/2560 BE.
//  Copyright © 2560 Supphawit Getmark. All rights reserved.
//

import UIKit
import CoreML

struct DotPosition: Hashable{
    
    var x:UInt32
    var y:UInt32

    var hashValue: Int{
        return x.hashValue * y.hashValue &* 16777619
    }

    static func ==(lhs: DotPosition, rhs: DotPosition) -> Bool {
        return lhs.x == rhs.x && lhs.y == rhs.y
    }

}

@available(iOS 11.0, *)
class DotViewController: UIViewController, CameraControllerDelegate {
    
    //MARK:- Propreties
    let generateRandomCircle = true
    let cameraController = CameraController()
    static let circleRadius: CGFloat = 20
    
    
    var dotCount = 0
    var dotPosition: DotPosition = DotPosition(x: 0, y: 0)
    var isProcessing = false
    var gazeLogic: EyeGazeLogic?
    var result: [DotPosition: [PredictPoint]] = [:]
    lazy var circleDrawTimer: Timer = Timer.init()
    
    
    
    //MARK:- ViewAction
    override func viewDidLoad() {
        super.viewDidLoad()
        cameraController.prepare(completionHandler: {(error) in
            if let error = error{
                print(error)
            }
        })
        self.drawCircle()
        DispatchQueue.global().async {
            self.gazeLogic = EyeGazeLogic()
            self.cameraController.delegate = self
        }
        if(self.generateRandomCircle){
            self.circleDrawTimer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(self.drawCircle), userInfo: nil, repeats: true)
        }
    }
    
    @objc func drawCircle(){
        let screenRect = UIScreen.main.bounds
        self.dotPosition.x = arc4random_uniform(UInt32(screenRect.width-DotViewController.circleRadius)) + UInt32(DotViewController.circleRadius)
        self.dotPosition.y = arc4random_uniform(UInt32(screenRect.height-DotViewController.circleRadius)) + UInt32(DotViewController.circleRadius)
        let circlePath = UIBezierPath(
            arcCenter: CGPoint(x: Double(self.dotPosition.x)
            , y: Double(self.dotPosition.y))
            , radius: DotViewController.circleRadius
            , startAngle: CGFloat(0)
            , endAngle: CGFloat(Double.pi*2)
            , clockwise: true)
        let shapelayer = CAShapeLayer()
        shapelayer.path = circlePath.cgPath
        shapelayer.fillColor = UIColor.red.cgColor
        shapelayer.strokeColor = UIColor.red.cgColor
        shapelayer.lineWidth = 3.0
        guard let layerCount = self.view.layer.sublayers?.count else {
            self.view.layer.addSublayer(shapelayer)
            return
        }
        if(layerCount == 1){
            self.view.layer.sublayers?.removeLast()
        }
        self.view.layer.addSublayer(shapelayer)
        dotCount += 1
        if(dotCount > 9){
            self.performSegue(withIdentifier: "showPredictResultSegue", sender: nil)
        }
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == "showPredictResultSegue"){
            let destination  = segue.destination as! ShowResultViewController
            destination.predictResults = result
        }
    }
    
    //MARK:- DelegateMethod
    func didCaptureVideoFrame(image: CIImage) {
        if(!isProcessing){
            DispatchQueue.global(qos: .userInteractive).async {
                do {
                    self.isProcessing = true
                    guard let result = try self.gazeLogic?.detectEye(on: image) else {
                        self.isProcessing = false
                        return
                    }
                    if self.result[self.dotPosition] != nil{
                        self.result[self.dotPosition]!.append(result)
                    }
                    else{
                        self.result[self.dotPosition] = [result]
                    }
                }
                catch{
                    print(error)
                }
                self.isProcessing = false
            }
        }
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

