// Copyright © 2024 Charles Kerr. All rights reserved.

import Foundation
import AppKit


func renderSequence( duration:Double, effects:[ItemEffect], lightBundle:LightBundle,grids:[TimeGrid], patternBase:URL,imageBase:URL, framePeriod:Int) throws -> [[PixelColor]]{
    let amountOfLights = lightBundle.lights.count
    
    let frameCount = Int(duration / (Double(framePeriod) / 1000.0)) + 1
    var frames = [[PixelColor]].init(repeating: [PixelColor].init(repeating: PixelColor(), count: amountOfLights), count: frameCount)
    
    let patternDirectory = patternBase.appending(path: lightBundle.bundlePatternDirectory)
    let imageDirectory = imageBase.appending(path: lightBundle.bundleImageDirectory)
    let imageCache = ImageCache()
    let patternCache = PatternCache()
    
    // Sort the  effects
    let sortedEffects = effects.sorted { lhs, rhs in
        guard lhs.effectLayer < rhs.effectLayer else { return false }
        guard lhs.effectLayer == rhs.effectLayer  else { return true }
        guard lhs.startTime  <= rhs.startTime    else { return false }
        guard lhs.startTime == rhs.startTime else { return true }
        guard lhs.endTime <= rhs.endTime else { return false }
        return true
    }
    for effect in sortedEffects {
        //Swift.print("Applying effect \(effect.description)")
        guard let grid = grids.first(where: {$0.name == effect.gridName!}) else {
            throw GeneralError(errorMessage: "Effect: \(effect.description) time grid can not be found")
        }
        // now, get our times
        let times = grid.timesBetweenInclusive(startTime: effect.startTime, endTime: effect.endTime)
        //Swift.print("\(grid.name!) has \(times.count) time points within (inclusive)  \(effect.startTime) and \(effect.endTime)")
        // We have three things, we have a light, an pixeleffect, and a time entry
        if times.count >= 2 {
            let patternData = try patternCache.patternFor(base: patternDirectory, key: effect.pattern!)
            var transistionIndex = 0
            if !patternData.isEmpty {
                for timeIndex in 0..<times.count-1 {
                    
                    if transistionIndex >= patternData.count {
                        transistionIndex = 0
                    }
                    let pixelEffects = patternData[transistionIndex]
                    
                    for pixelEffect in pixelEffects {
                        //Swift.print("Applying effect: \(pixelEffect.description) for time range \(times[timeIndex]) - \(times[timeIndex+1])")
                        let startOrigin = pixelEffect.startOrigin
                        let endOrigin = pixelEffect.endOrigin
                        let maskOrigin = pixelEffect.maskOrigin
                        let startImage = try imageCache.imageFor(base: imageDirectory, key: pixelEffect.startImage!)
                        let endImage = try imageCache.imageFor(base: imageDirectory, key: pixelEffect.endImage!)
                        let maskImage = try imageCache.imageFor(base: imageDirectory, key: pixelEffect.maskImage!)
                        let startTime = times[timeIndex]
                        let endTime = times[timeIndex+1]
                        let (frameIndex,frameCount) = calculateFrameOffsetCount(startMill: startTime, endMilli: endTime, framePeriod: BlinkyGlobals.framePeriod)
                        
                        for lightIndex in 0..<lightBundle.lights.count {
                            
                            let startColor = PixelColor.colorFromRep(imageRep: startImage, point: NSPoint(x:startOrigin.x + lightBundle.lights[lightIndex].imageOrigin.x, y: startOrigin.y + lightBundle.lights[lightIndex].imageOrigin.y))
                            let endColor = PixelColor.colorFromRep(imageRep: endImage, point: NSPoint(x:endOrigin.x + lightBundle.lights[lightIndex].imageOrigin.x, y: endOrigin.y + lightBundle.lights[lightIndex].imageOrigin.y))
                            let maskColor = PixelColor.colorFromRep(imageRep: maskImage, point: NSPoint(x:maskOrigin.x + lightBundle.lights[lightIndex].imageOrigin.x, y: maskOrigin.y + lightBundle.lights[lightIndex].imageOrigin.y))
                            if maskColor.red > 0 {
                                applyPixelEffect(pixelEffect:pixelEffect.pixelEffect, frames: &frames, frameOffset: frameIndex, frameCount: frameCount, lightIndex: lightIndex, startColor: startColor, endColor: endColor, maskColor: maskColor)
                            }
                        }
                    }
                    transistionIndex += 1
                }
            }
        }
    }
    return frames
}

func calculateFrameOffsetCount(startMill:Int, endMilli:Int, framePeriod:Int) -> (Int,Int) {
    let offset = startMill / framePeriod
    let endoffset = endMilli / framePeriod
    return (offset,(endoffset - offset) + 1 )
}


func applyPixelEffect(pixelEffect:TransitionType.PixelEffectType, frames: inout [[PixelColor]],frameOffset:Int,frameCount:Int, lightIndex:Int,  startColor:PixelColor,endColor:PixelColor,maskColor:PixelColor) {
    //Swift.print("Applying \(pixelEffect.rawValue) with startColor: \(startColor.description)  endColor: \(endColor.description) maskColor: \(maskColor.description)")
    switch pixelEffect {
    case .add:
        applyAddPixelEffect(frames: &frames,frameOffset:frameOffset,frameCount: frameCount, lightIndex: lightIndex, startColor: startColor, endColor: endColor, maskColor: maskColor)
    case .blend:
        applyBlendPixelEffect(frames: &frames,frameOffset:frameOffset,frameCount: frameCount, lightIndex: lightIndex, startColor: startColor, endColor: endColor, maskColor: maskColor)
    case .color:
        applyColorPixelEffect(frames: &frames,frameOffset:frameOffset,frameCount: frameCount, lightIndex: lightIndex, startColor: startColor, endColor: endColor, maskColor: maskColor)
    case .random:
        applyRandomPixelEffect(frames: &frames,frameOffset:frameOffset,frameCount: frameCount, lightIndex: lightIndex, startColor: startColor, endColor: endColor, maskColor: maskColor)
    case .shimmer:
        applyShimmerPixelEffect(frames: &frames,frameOffset:frameOffset,frameCount: frameCount, lightIndex: lightIndex, startColor: startColor, endColor: endColor, maskColor: maskColor)
    case .sparkle:
        applySparklePixelEffect(frames: &frames,frameOffset:frameOffset,frameCount: frameCount, lightIndex: lightIndex, startColor: startColor, endColor: endColor, maskColor: maskColor)
    case .twinkle:
        applyTwinklePixelEffect(frames: &frames,frameOffset:frameOffset,frameCount: frameCount, lightIndex: lightIndex, startColor: startColor, endColor: endColor, maskColor: maskColor)
    case .diminish:
        applyDiminishPixelEffect(frames: &frames,frameOffset:frameOffset,frameCount: frameCount, lightIndex: lightIndex, startColor: startColor, endColor: endColor, maskColor: maskColor)
    default:
        break;
    }
}
//

func applyAddPixelEffect(frames: inout [[PixelColor]],frameOffset:Int,frameCount:Int, lightIndex:Int, startColor:PixelColor,endColor:PixelColor,maskColor:PixelColor ) {
    let newColors = PixelColor.colorsFor(start: startColor, end: endColor, count: frameCount)
    for frame in frameOffset..<frameOffset+frameCount {
        let color = PixelColor.add(lhs: frames[frame][lightIndex].copy() as! PixelColor,rhs:newColors[frame - frameOffset])
        frames[frame][lightIndex] = color
        //Swift.print("Set color to \(frames[frame][lightIndex].description)")
    }
}

func applyBlendPixelEffect(frames: inout [[PixelColor]], frameOffset:Int,frameCount:Int, lightIndex:Int, startColor:PixelColor,endColor:PixelColor,maskColor:PixelColor ) {
    let newColors = PixelColor.colorsFor(start: startColor, end: endColor, count: frameCount)
    for frame in frameOffset..<frameOffset+frameCount {
        let color = frames[frame][lightIndex].nsColor.blended(withFraction: maskColor.floatRed, of: newColors[frame - frameOffset].nsColor)
        
        frames[frame][lightIndex] = PixelColor(nsColor: color ?? frames[frame][lightIndex].nsColor)
        //Swift.print("Set color to \(frames[frame][lightIndex].description)")
    }
}

func applyColorPixelEffect(frames: inout [[PixelColor]], frameOffset:Int,frameCount:Int, lightIndex:Int, startColor:PixelColor,endColor:PixelColor,maskColor:PixelColor ) {
    let newColors = PixelColor.colorsFor(start: startColor, end: endColor, count: frameCount)
    for frame in frameOffset..<frameOffset+frameCount {
        frames[frame][lightIndex] = newColors[frame - frameOffset]
        //Swift.print("Set frame \(frame) light \(lightIndex) color to \(frames[frame][lightIndex].description)")
    }
}

func applyRandomPixelEffect(frames: inout [[PixelColor]], frameOffset:Int,frameCount:Int, lightIndex:Int, startColor:PixelColor,endColor:PixelColor,maskColor:PixelColor ) {
    let holdTime = Int(endColor.red) / BlinkyGlobals.framePeriod
    var holdCount = Int.random(in: 0...5) + holdTime
    var randomColor:PixelColor?
    for frame in frameOffset..<frameOffset+frameCount {
        if randomColor == nil {
            randomColor = PixelColor.randomColor
            holdCount = Int.random(in: 0...5) + holdTime
        }
        frames[frame][lightIndex] = randomColor!
        //Swift.print("Set color to \(frames[frame][lightIndex].description)")
        holdCount -= 1
        if holdCount == 0 {
            randomColor = nil
        }
    }
}

func applyShimmerPixelEffect(frames: inout [[PixelColor]], frameOffset:Int,frameCount:Int, lightIndex:Int, startColor:PixelColor,endColor:PixelColor,maskColor:PixelColor ) {
    /*
    var blankColor = false
    for frame in frameOffset..<frameOffset+frameCount {
        if blankColor {
            frames[frame][lightIndex] = PixelColor()
            blankColor = !blankColor
        }
        else { 
             blankColor = !blankColor
        }
    }
     */
    let holdTime = Int(startColor.red)/32

    var blank = false
    var resetTime = holdTime
    for frame in frameOffset..<frameOffset+frameCount {
        if !blank {
            resetTime -= 1
            if resetTime < 0 {
                blank = !blank
                resetTime = holdTime
            }
        }
        else {
            frames[frame][lightIndex] = PixelColor()
            resetTime -= 1
            if resetTime < 0 {
                blank = !blank
                resetTime = holdTime
            }

        }
    }

}

func applySparklePixelEffect(frames: inout [[PixelColor]], frameOffset:Int,frameCount:Int, lightIndex:Int, startColor:PixelColor,endColor:PixelColor,maskColor:PixelColor ) {
    let normalTime = Int(startColor.red)/BlinkyGlobals.framePeriod
    let holdTime = Int(endColor.red)/BlinkyGlobals.framePeriod
    var shouldHold = Int.random(in: 0...5) + holdTime
    var shouldKeep = Int.random(in: 0...5) + normalTime
    var shouldSparkle = Int.random(in:0...1)
    for frame in frameOffset..<frameOffset+frameCount {
        if shouldSparkle == 1 {
            frames[frame][lightIndex] = frames[frame][lightIndex].maxIntensity
            //Swift.print("Set color to \(frames[frame][lightIndex].description)")
            shouldHold -= 1
            if shouldHold <= 0 {
                shouldSparkle = 0
                shouldKeep = Int.random(in: 0...5) + normalTime
            }
        }
        else {
            shouldKeep -= 1
            if shouldKeep <= 0 {
                shouldSparkle = 1
                shouldHold = Int.random(in: 0...5) + holdTime
            }
        }
    }
}

func applyTwinklePixelEffect(frames: inout [[PixelColor]], frameOffset:Int,frameCount:Int, lightIndex:Int, startColor:PixelColor,endColor:PixelColor,maskColor:PixelColor ) {
    let normalTime = Int(startColor.red)/BlinkyGlobals.framePeriod
    let holdTime = Int(endColor.red)/BlinkyGlobals.framePeriod
    var shouldHold = Int.random(in: 0...5) + holdTime
    var shouldKeep = Int.random(in: 0...5) + normalTime
    var shouldSparkle = Int.random(in:0...1)
    for frame in frameOffset..<frameOffset+frameCount {
        if shouldSparkle == 1 {
            frames[frame][lightIndex] = frames[frame][lightIndex].colorAtLevel(intensity: 0.0)
            //Swift.print("Set color to \(frames[frame][lightIndex].description)")
            shouldHold -= 1
            if shouldHold <= 0 {
                shouldSparkle = 0
                shouldKeep = Int.random(in: 0...5) + normalTime
            }
        }
        else {
            shouldKeep -= 1
            if shouldKeep <= 0 {
                shouldSparkle = 1
                shouldHold = Int.random(in: 0...5) + holdTime
            }
        }
    }
}

func applyDiminishPixelEffect(frames: inout [[PixelColor]], frameOffset:Int,frameCount:Int, lightIndex:Int, startColor:PixelColor,endColor:PixelColor,maskColor:PixelColor ) {
    let startIntensity = startColor.floatRed
    let endIntensity = endColor.floatRed
    if frameCount > 1 {
        let step = (endIntensity - startIntensity) / Double(frameCount - 1 )
        var intensity = startIntensity
        
        for frame in frameOffset..<frameOffset+frameCount {
            frames[frame][lightIndex] = frames[frame][lightIndex].colorAtLevel(intensity: intensity)
            //Swift.print("Set color to \(frames[frame][lightIndex].description)")
            intensity += step
        }
    }
}
