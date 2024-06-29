// Copyright © 2024 Charles Kerr. All rights reserved.

import Foundation
import AppKit

extension NSColor {
    
    @objc dynamic var stringValue:String {
            let format = "%1.4f,%1.4f,%1.4f,%1.4f"
            guard let temp = self.usingColorSpace(NSColorSpace.deviceRGB) else { return String(format: format , 0.0 ,0.0 , 0.0 , 0.0)}
            let red = temp.redComponent
            let green = temp.greenComponent
            let blue = temp.blueComponent
            let alpha = temp.alphaComponent
            return String(format: format , red ,green , blue , alpha)
    }
    
    func setIntensity(value:Double) -> NSColor {
        var intensity = max(value,0.0)
        intensity = min(intensity,1.0)
        // First thing we need to do is make a copy of ourself
        var temp = self.copy() as! NSColor
        temp = temp.usingColorSpace(NSColorSpace.deviceRGB) ?? NSColor(deviceRed: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        // We now know we have a red/green/blue component
        var red = temp.redComponent
        var green = temp.greenComponent
        var blue = temp.blueComponent
        let maxValue = max(max(red,green),blue)
        let alpha = temp.alphaComponent
        
        red = (red/maxValue) * intensity
        green = green/maxValue * intensity
        blue = blue/maxValue * intensity
        return NSColor(deviceRed: red, green: green, blue: blue, alpha: alpha)
    }
    
    static func colorFrom(string value:String) -> NSColor {
        let values = value.components(separatedBy: ",").map{ Double($0.trimmingCharacters(in: .whitespaces)) ?? 0.0 }
        switch values.count {
        case 4:
            return NSColor(deviceRed: values[0], green: values[1], blue: values[2], alpha: values[3])
        case 3:
            return NSColor(deviceRed: values[0], green: values[1], blue: values[2], alpha: 1.0 )
        case 2:
            return NSColor(deviceRed: values[0], green: values[1], blue: 0.0 , alpha: 1.0 )
        case 1:
            return NSColor(deviceRed: values[0], green: 0.0, blue: 0.0 , alpha: 1.0 )
        case 0:
            return NSColor(deviceRed: 0.0 , green: 0.0, blue: 0.0 , alpha: 0.0 )
        default:
            return NSColor(deviceRed: values[0], green: values[1], blue: values[2], alpha: values[3])
        }
    }
}
