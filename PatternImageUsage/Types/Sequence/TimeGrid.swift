// Copyright © 2024 Charles Kerr. All rights reserved.

import Foundation
import AppKit

class TimeGrid : NSObject,Codable {
    
    enum Codingkeys : CodingKey {
        case name,color,timeEntries
    }
    
    @objc dynamic var name:String?
    @objc dynamic var color = NSColor.red
    
    @objc dynamic var lastTime:Double {
        timeEntries.max()?.milliSeconds ?? 0.0
    }
    @objc dynamic var firstTime:Double {
        timeEntries.min()?.milliSeconds ?? 0.0
    }

    var timeEntries = Set<Int>() 
    var isScratch:Bool {
        return self.name == "Scratch"
    }
    init(name: String? = nil, color: NSColor = NSColor.red, timeEntries: Set<Int> = Set<Int>()) {
        self.name = name
        self.color = color
        self.timeEntries = timeEntries
    }
    
    required init(from decoder: any Decoder) throws {
        super.init()
        let container = try decoder.container(keyedBy: Codingkeys.self)
        
        name = try container.decode(String?.self,forKey: .name)
        let temp = try container.decode(String.self,forKey: .color)
        color = NSColor.colorFrom(string: temp)
        timeEntries = try container.decode(Set<Int>.self, forKey: .timeEntries)
    }
    
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: Codingkeys.self)
        
        try container.encode(name, forKey: .name)
        try container.encode(color.stringValue, forKey: .color)
        try container.encode(timeEntries, forKey: .timeEntries)
    }
    
    override var description: String {
        return self.name ?? "none"
    }
}

// ============  NSCopying
extension TimeGrid : NSCopying {
    func copy(with zone: NSZone? = nil) -> Any {
        return TimeGrid(name: self.name, color: self.color.copy() as! NSColor, timeEntries: timeEntries)
    }
}

// ============  XML
extension TimeGrid {
    
    var xml:XMLElement {
        let element = XMLElement(name: "timingGrid")
        
        var node = XMLNode(kind: .attribute)
        node.name = "name"
        node.stringValue = self.name
        element.addAttribute(node)
        
        node = XMLNode(kind: .attribute)
        node.name = "color"
        node.stringValue = color.stringValue
        element.addAttribute(node)

        for time in timeEntries.sorted(by: {$0 < $1}) {
            let child = XMLElement(name:"timeEntry")
            let node = XMLNode(kind:.attribute)
            node.name = "time"
            node.stringValue = time.milliString
            child.addAttribute(node)
            element.addChild(child)
        }
        return element
    }
    
    convenience init(element:XMLElement) throws {
        self.init()
        guard element.name == "timingGrid"  else {
            throw GeneralError(errorMessage: "Invalid element name for TimeGrid: \(element.name ?? "")")
        }
        var node = element.attribute(forName: "name")
        guard node?.stringValue != nil else {
            throw GeneralError(errorMessage: "Missing name attribute for TimeGrid")
        }
        self.name = node!.stringValue!
        
        node = element.attribute(forName: "color")
        guard node?.stringValue != nil else {
            throw GeneralError(errorMessage: "Missing color attribute for TimeGrid")
        }
        self.color = NSColor.colorFrom(string: node!.stringValue!)
        for child in element.elements(forName: "timing") {
            let node = child.attribute(forName: "time")
            guard node?.stringValue != nil else {
                throw GeneralError(errorMessage: "Missing time attribute on TimeEntry/Timing")
            }
            guard let value = Double(node!.stringValue!) else {
                throw GeneralError(errorMessage: "Invalid time attribute on TimeEntry/Timing: \(node!.stringValue!)")
            }
            timeEntries.insert(value.milliSeconds)
        }
        for child in element.elements(forName: "timeEntry") {
            let node = child.attribute(forName: "time")
            guard node?.stringValue != nil else {
                throw GeneralError(errorMessage: "Missing time attribute on TimeEntry/Timing")
            }
            guard let value = Double(node!.stringValue!) else {
                throw GeneralError(errorMessage: "Invalid time attribute on TimeEntry/Timing: \(node!.stringValue!)")
            }
            timeEntries.insert(value.milliSeconds)
        }
    }
}

// ============  Finding times
extension TimeGrid {
    func findTime(milliseconds:Int, tolerance:Int = 5) -> Int? {
        let range = milliseconds - tolerance...milliseconds + tolerance
        for time in timeEntries.sorted() {
            if range.contains(time) {
                return time
            }
        }
        return nil
    }
    func findTimeBeforeEqual(milliseconds:Int ) -> Int? {
        var lastTime:Int?
        for time in timeEntries.sorted() {
            if time > milliseconds {
                break
            }
            else {
                lastTime = time
            }
        }
        return lastTime
    }
    func findTimeAfterEqual(milliseconds:Int) -> Int? {
        var lastTime:Int?
        for time in timeEntries.sorted().reversed() {
            if time < milliseconds {
                break
            }
            else {
                lastTime = time
            }
        }
        return lastTime
    }

    func bestTimeFor(milliseconds:Int,preferBefore:Bool = true ) -> Int? {
        let beforeTime = findTimeBeforeEqual(milliseconds: milliseconds)
        let afterTime = findTimeAfterEqual(milliseconds: milliseconds)
        guard beforeTime != nil else { return afterTime}
        guard afterTime != nil else { return beforeTime}
        let beforeDelta = milliseconds - beforeTime!
        let afterDelta = afterTime! - milliseconds
        guard beforeDelta <= afterDelta else { return afterTime!}
        guard beforeDelta == afterDelta else { return beforeTime!}
        // They are the same distance, so look at preference
        return preferBefore ? beforeTime : afterTime

    }
    
    func timesBetweenInclusive(startTime:Int, endTime:Int) -> [Int] {
        var rvalue = [Int]()
        for time in timeEntries.sorted() {
            if time >= startTime && time <= endTime {
                rvalue.append(time)
            }
            if time > endTime {
                break
            }
        }
        return rvalue 
    }
}
