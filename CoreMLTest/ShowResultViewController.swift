//
//  ShowResultViewController.swift
//  CoreMLTest
//
//  Created by Supphawit Getmark on 9/14/2560 BE.
//  Copyright © 2560 Supphawit Getmark. All rights reserved.
//

import Foundation
import UIKit

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
    }
}
