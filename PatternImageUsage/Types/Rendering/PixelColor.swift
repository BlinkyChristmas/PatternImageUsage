// Copyright © 2024 Charles Kerr. All rights reserved.

import Foundation
import AppKit

class PixelColor : NSObject {
    var colors = [UInt8(0),UInt8(0),UInt8(0)]
    
    var red:UInt8 {
        get{
            return colors[0]
        }
        set {
            colors[0] = newValue
        }
    }
    var green:UInt8 {
        get {
            return colors[1]
        }
        set {
            colors[1] = newValue
        }
    }
    var blue:UInt8 {
        get {
            return colors[2]
        }
        set {
            colors[2] = newValue
        }
    }
    var isIntensity = false
    
}
// ======== NSCopying
extension PixelColor : NSCopying {
    func copy(with zone: NSZone? = nil) -> Any {
        let color = PixelColor()
        color.red = self.red
        color.green = self.green
        color.blue = self.blue
        color.isIntensity = self.isIntensity
        return color
    }
}

// ======== General support
extension PixelColor {
    convenience init(red:UInt8,green:UInt8,blue:UInt8) {
        self.init()
        self.red = red
        self.green = green
        self.blue = blue
    }
    convenience init(redFloat:Double,greenFloat:Double,blueFloat:Double) {
        self.init()
        //Swift.print("Convience init called with: \(redFloat) , \(greenFloat), \(blueFloat)")
        self.floatRed = redFloat
        self.floatGreen = greenFloat
        self.floatBlue = blueFloat
    }
    var isBlack:Bool {
        if isIntensity {
            return red == 0
        }
        else {
            return red == green && green == blue && blue == 0
        }
    }
    var floatRed:Double {
        get{
            return min(Double(red)/255.0,1.0)
        }
        set{
            red = UInt8(min( Int( (min(1.0,newValue) * 255.0).rounded()),255))
        }
    }
    var floatGreen:Double {
        get{
            return min(Double(green)/255.0,1.0)
        }
        set{
            green = UInt8(min( Int( (min(1.0,newValue) * 255.0).rounded()),255))
        }
    }
    var floatBlue:Double {
        get{
            return min(Double(blue)/255.0,1.0)
        }
        set{
            blue = UInt8(min( Int( (min(1.0,newValue) * 255.0).rounded()),255))
        }
    }
    
    static func add(lhs:PixelColor,rhs:PixelColor) -> PixelColor {
        let newred = Int(lhs.red) +  Int(rhs.red)
        let newgreen =  Int(lhs.green) +  Int(rhs.green)
        let newblue = Int(lhs.blue) +  Int(rhs.blue)
        return PixelColor(red: UInt8(min(newred,255)), green: UInt8(min(newgreen,255)), blue: UInt8(min(newblue,255)))
    }
}

// ======= NSColor
extension PixelColor {
    convenience init(nsColor:NSColor) {
        self.init()
        if nsColor.colorSpace == NSColorSpace.deviceGray || nsColor.colorSpace == NSColorSpace.genericGray {
            isIntensity = true
            red = UInt8((nsColor.whiteComponent * 255.0).rounded())
        }
        else if nsColor.colorSpace == NSColorSpace.deviceRGB || nsColor.colorSpace == NSColorSpace.genericRGB {
            isIntensity = false
            red = UInt8((nsColor.redComponent * 255.0).rounded())
            green = UInt8((nsColor.greenComponent * 255.0).rounded())
            blue = UInt8((nsColor.blueComponent * 255.0).rounded())
        }
    }

    var nsColor:NSColor {
        if isIntensity {
            return NSColor(deviceWhite: Double(red)/255.0, alpha: 1.0)
        }
        return NSColor(deviceRed: Double(red)/255.0, green: Double(green)/255.0, blue: Double(blue)/255.0, alpha: 1.0)
    }
    
    static func addColor(lhs:PixelColor,rhs:PixelColor,fraction:Double) -> PixelColor {
        var base = lhs.nsColor
        let addition = rhs.nsColor
        base = base.blended(withFraction: fraction, of: addition) ?? NSColor.black
        return PixelColor(nsColor: base)
    }
    
    override var description: String {
        return String(format:"%.3f,%.3f,%.3f,%.3f", self.floatRed,self.floatGreen,self.floatBlue,1.0)
    }
}

// ======== Intensity related
extension PixelColor {
    convenience init(intensity:Double) {
        self.init()
        isIntensity = true
        red = UInt8((255.0 * intensity).rounded())
    }
    var currentIntensity:Double {
        var maxIntensity = Double(red)/255.0
        maxIntensity = max(Double(green)/255.0,maxIntensity)
        return max(Double(blue)/255.0,maxIntensity)
    }
    var maxIntensity:PixelColor {
        let temp = self.currentIntensity
        var percent = 0.0
        if temp > 0.0 {
            percent = 1.0 / temp
        }
        return PixelColor(redFloat: self.floatRed * percent, greenFloat: self.floatGreen * percent, blueFloat: self.floatBlue * percent)
    }

    func colorAtLevel(intensity:Double) -> PixelColor {
        let current = currentIntensity
        var toSet = intensity
        if current > 0.0 {
            let maxIntensity =  1.0 / current
            toSet = min(intensity,maxIntensity)
        }
        return PixelColor(redFloat: self.floatRed * toSet, greenFloat: self.floatGreen * toSet, blueFloat: self.floatBlue * toSet)
    }
}

// ============ Transistion support
extension PixelColor {
    static var randomColor:PixelColor {
        switch Int.random(in: 0...7) {
        case 0:
            return PixelColor(red: 0, green: 0, blue: 0)
        case 1:
            return PixelColor(red: 255, green: 0, blue: 0)
        case 2:
            return PixelColor(red: 0, green: 255, blue: 0)
        case 3:
            return PixelColor(red: 0, green: 0, blue: 255)
        case 4:
            return PixelColor(red: 255, green: 255, blue: 255)
        case 5:
            return PixelColor(red: 255, green: 255, blue: 0)
        case 6:
            return PixelColor(red: 0, green: 255, blue: 255)
        case 7:
            return PixelColor(red: 255, green: 0, blue: 255)
        default:
            return PixelColor()
        }
    }

    static func colorFromRep(imageRep:NSBitmapImageRep,point:NSPoint) ->  PixelColor {
        var color = PixelColor()
        let width = imageRep.pixelsWide
        let height = imageRep.pixelsHigh
        let x = Int(point.x)
        let y = Int(point.y)
        if width > x && height > y {
            let nscolor = imageRep.colorAt(x: x, y: y)
            if nscolor != nil {
                color = PixelColor(nsColor: nscolor!)
            }
        }
        return color
    }
    
    static func colorsFor(start:PixelColor,end:PixelColor,count:Int) -> [PixelColor] {
        var rvalue = [PixelColor]()
        guard count > 0 else { return rvalue }
        guard count > 1 else { return [start]}
        
        let redDelta = (start.floatRed - end.floatRed) / Double(count - 1)
        let greenDelta = (start.floatGreen - end.floatGreen) / Double(count - 1)
        let blueDelta = (start.floatBlue - end.floatBlue) / Double( count - 1 )
        for index in 0..<count {
            rvalue.append(PixelColor(redFloat: start.floatRed - Double(index) * redDelta , greenFloat:  start.floatGreen - Double(index) * greenDelta, blueFloat:  start.floatBlue - Double(index) * blueDelta))
        }
        return rvalue
    }
    
    static func colorsForRange(startMilli:Int,endMilli:Int,startColor:PixelColor,endColor:PixelColor,framePeriod:Int = BlinkyGlobals.framePeriod) -> [PixelColor] {
        let count = (endMilli - startMilli)/framePeriod
        return colorsFor(start: startColor, end: endColor, count: count+1)
    }
}
