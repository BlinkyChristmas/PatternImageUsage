// Copyright © 2024 Charles Kerr. All rights reserved.

import Foundation
import CoreGraphics

extension CGColor {
    var stringValue:String {
        // Convert to a device colorspace
        var converted  = self
        if (self.colorSpace?.name != CGColorSpace.sRGB) {
            guard let temp = self.converted(to: CGColorSpace(name: CGColorSpace.sRGB)!, intent: .defaultIntent, options: nil) else {
                return "0.0,0.0,0.0,0.0"
            }
            converted = temp
        }
        guard let values = converted.components else { return "0.0,0.0,0.0,0.0" }
        guard values.count == 4 else {return "0.0,0.0,0.0,0.0" }
        return String(format:"%.3f,%.3f,%.3f,%.3f",values[0],values[1],values[2],values[3])
    }
    
    static func colorFor(string:String) -> CGColor {
        var values = string.components(separatedBy: ",").map{$0.trimmingCharacters(in: .whitespaces)}.map{Double($0) ?? 0.0 }
        if values.count < 3 {
            let toAdd = 3 - values.count
            for _ in 0..<toAdd {
                values.append(0.0)
            }
        }
        if values.count < 4 {
            values.append(1.0)
        }
        return CGColor(srgbRed: values[0], green: values[1], blue: values[2], alpha: values[3])
    }
    
    func setIntensity(value:Double) -> CGColor {
        var converted  = self
        if (self.colorSpace?.name != CGColorSpace.sRGB) {
            var temp = self.converted(to: CGColorSpace(name: CGColorSpace.sRGB)!, intent: .defaultIntent, options: nil)
            if temp == nil {
                temp = CGColor(srgbRed: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
            }
            converted = temp!
        }
        var intensity = max(value,0.0)
        intensity = min(intensity,1.0)
        var red = converted.components![0]
        var green = converted.components![1]
        var blue = converted.components![2]
        let alpha = converted.alpha
        let maxValue = max(max(red,green),blue)
        red = (red/maxValue) * intensity
        green = green/maxValue * intensity
        blue = blue/maxValue * intensity
        return CGColor(srgbRed: red, green: green, blue: blue, alpha: alpha)
    }
    
    func colorFor(values:[UInt8]) -> CGColor {
        guard values.count == 3 || values.count == 1  else { return CGColor.black}
        if values.count == 3 {
            return CGColor(srgbRed: Double(values[0])/255.0, green: Double(values[1])/255.0, blue: Double(values[2])/255.0, alpha: 1.0)
        }
        return self.colorFor(value: values[0])
    }
    func colorFor(value:UInt8) -> CGColor {
        return CGColor(srgbRed: Double(value)/255.0, green: Double(value)/255.0, blue: Double(value)/255.0, alpha: 1.0)
    }
}
