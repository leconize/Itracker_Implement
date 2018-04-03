//
//  CGRectExtension.swift
//  CoreMLTest
//
//  Created by Supphawit Getmark on 27/3/2561 BE.
//  Copyright © 2561 Supphawit Getmark. All rights reserved.
//

import Foundation
import CoreGraphics

extension CGRect {
    
    // Flip the x-axis. Useful for switching between image data and display
    // (which is mirrored).
    func rectWithFlippedX(inFrame frame: CGSize) -> CGRect {
        return CGRect(
            x: frame.width - (self.origin.x + self.size.width),
            y: self.origin.y,
            width: self.size.width,
            height: self.size.height)
    }
    
    func rectWithFlippedX(inFrame frame: CGRect) -> CGRect {
        return self.rectWithFlippedX(inFrame: frame.size)
    }
    
    // Flip the y-axis. Useful for converting from CI to UI or vice versa.
    func rectWithFlippedY(inFrame frame: CGSize) -> CGRect {
        return CGRect(
            x: self.origin.x,
            y: frame.height - (self.origin.y + self.size.height),
            width: self.size.width,
            height: self.size.height)
    }
}

extension CGPoint {
    
    func euclideanDistance(from point: CGPoint) -> CGFloat {
        
        return pow( pow(self.x-point.x, 2) + pow(self.y-point.y, 2), 0.5 )
    }
}
