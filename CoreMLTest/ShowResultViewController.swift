//
//  ShowResultViewController.swift
//  CoreMLTest
//
//  Created by Supphawit Getmark on 9/14/2560 BE.
//  Copyright © 2560 Supphawit Getmark. All rights reserved.
//

import Foundation
import UIKit
import MessageUI

class ShowResultViewController: UIViewController, MFMailComposeViewControllerDelegate{
    
    @IBOutlet weak var result: UITextView!
    
    var predictResults: [DotPosition: [PredictPoint]] = [:]
    
    override func viewDidLoad() {
        result.text = createCsvFrom(result: predictResults)
        let hitRate = calAccuracy(result: predictResults)
        print(hitRate)
        
    }
    @IBAction func sendEmailBtnAction() {
        self.sendEmail()
    }
    
    func createCsvFrom(result: [DotPosition: [PredictPoint]]) -> String{
        var stringResult: String = ""
        print()
        for item in result{
            stringResult.append("\(item.key.x),\(item.key.y)\n")
            for predictPoint in item.value{
                stringResult.append("\(predictPoint.posX), \(predictPoint.posY),\(predictPoint.toScreenPoint().x),\(predictPoint.toScreenPoint().y)\n")
            }
        }
        print(stringResult)
        return stringResult
    }
    
    func sendEmail() -> Void {
        let mailMVC = MFMailComposeViewController()
        mailMVC.mailComposeDelegate = self
        mailMVC.setToRecipients(["g.supavit@gmail.com"])
        mailMVC.setSubject("send position")
        mailMVC.setMessageBody(self.createCsvFrom(result: predictResults), isHTML: false)
        self.present(mailMVC, animated: true, completion: nil)
    }
    
    func calAccuracy(result:[DotPosition: [PredictPoint]]) -> Double{
        var hitRate = 0
        var total = 0
        for predict in result{
            let circle = Circle(posX: Double(predict.key.x)
                , posY: Double(predict.key.y)
                , radius: Double(DotViewController.circleRadius))
            
            for predictResult in predict.value{
                total += 1
                if(circle.isPointInCircle(point: CGPoint(x: predictResult.posX, y: predictResult.posX))){
                    hitRate += 1
                }
                else{
                    
                }
            }
        }
        return Double(hitRate / total)
    }
    
    
}

struct Circle{
    
    let posX:Double
    let posY:Double
    
    let radius: Double
    
    func isPointInCircle(point: CGPoint) -> Bool{
        if(pow(Double(point.x)-posX, 2) + pow(Double(point.y)-posY, 2) < radius){
            return true
        }
        return false
    }
    
}
