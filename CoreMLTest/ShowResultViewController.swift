//
//  ShowResultViewController.swift
//  CoreMLTest
//
//  Created by Supphawit Getmark on 9/14/2560 BE.
//  Copyright © 2560 Supphawit Getmark. All rights reserved.
//

import Foundation
import UIKit

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
class ShowResultViewController: UIViewController{
    
    @IBOutlet weak var result: UITextView!
    
    var predictResults: [DotPosition: [PredictPoint]] = [:]
    
    override func viewDidLoad() {
        for item in predictResults{
            result.text.append("at Position(\(item.key.x), \(item.key.y)) = \n")
            for predictPoint in item.value{
                result.text.append("""
                    \(predictPoint.posX), \(predictPoint.posY) \n
                    Calculate = (\(predictPoint.toScreenPoint().x), \(predictPoint.toScreenPoint().y)) \n
""")
            }
        }
        let hitRate = calAccuracy(result: predictResults)
        print(hitRate)
        
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
