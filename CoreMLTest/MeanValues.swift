//
//  MeanValues.swift
//  CoreMLTest
//
//  Created by Supphawit Getmark on 8/28/2560 BE.
//  Copyright © 2560 Supphawit Getmark. All rights reserved.
//

import Foundation

class MeanValues{
    let means:[Double]
    
    init(means:[Double]) {
        self.means = means
    }
    
    init(filename:String) {
        func loadMean(file filename:String) -> String?{
            do {
                if let path = Bundle.main.path(forResource: filename, ofType: "txt"){
                    let data = try String(contentsOfFile:path, encoding: String.Encoding.utf8)
                    return data
                }
            }
            catch{
                return nil
            }
            return nil
        }
        
        func meanTextToArray(text: String) -> [Double]?{
            let textArray = text.components(separatedBy: "\n")
            var array: [Double] = [Double](repeatElement(0, count: 150528))
            var index = 0
            for line in 0..<textArray.count{
                if line != 0 && line != 225 && line != 450{
                    for column in textArray[line].components(separatedBy: " "){
                        if column.trimmingCharacters(in: .whitespaces) != ""{
                            guard let temp = Double(column) else {
                                print(textArray[line])
                                return nil
                            }
                            array[index] = temp
                            index += 1
                        }
                    }
                }
            }
            return array
        }
        
        self.means = meanTextToArray(text: loadMean(file: filename)!)!
    }
    
    //MARK:- Setup Mean
    
    
    
}
