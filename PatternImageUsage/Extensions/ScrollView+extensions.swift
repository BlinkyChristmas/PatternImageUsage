// Copyright © 2024 Charles Kerr. All rights reserved.

import Foundation
import AppKit

extension NSScrollView {
    func seekTo(seconds: Double, dotsPerSecond:Double) {
        var current = self.contentView.documentVisibleRect.origin

        var position = seconds * dotsPerSecond - self.contentView.bounds.width/2.0
        if position < 0.0  {
            position = 0.0
        }
        current.x = position
        self.documentView?.scroll(current)
    }
    
    func setScale(name:String) {
        self.horizontalRulerView?.measurementUnits = NSRulerView.UnitName(rawValue: name)
    }
    
    func registerScale(dotsPerSecond:Double,name:String, abbreviation:String ) {
        let stepUP = [NSNumber(value:Float(2.0))]
        let stepDown = [NSNumber(value: Float(0.1))]
        let scalename = NSRulerView.UnitName( name)
        NSRulerView.registerUnit(withName: scalename , abbreviation: abbreviation, unitToPointsConversionFactor: dotsPerSecond, stepUpCycle: stepUP, stepDownCycle: stepDown)
        self.horizontalRulerView?.measurementUnits = scalename
    }
    
}

