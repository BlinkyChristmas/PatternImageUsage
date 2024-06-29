// Copyright © 2024 Charles Kerr. All rights reserved.

import Foundation
import CoreGraphics
import AppKit
enum VisualType : String,CustomStringConvertible {
    case oval,rect,line
     
    var description: String {
        return self.rawValue
    }
}


struct Visual {
    var visualType = VisualType.oval
    var origin = CGPoint.zero
    var size = CGSize.zero
    var fill = false
    var color:CGColor?
    var lineWidth:Double?
    var phase:Double?
    var dash:[CGFloat]?
    var lightName:String?
    var points:[CGPoint]?
    var path:NSBezierPath?
}

extension Visual : XMLProtocol {
    var xml: XMLElement {
        let element = XMLElement(name:"visual")
        
        var node = XMLNode(kind: .attribute)
        node.name = "visualType"
        node.stringValue = visualType.description ;
        element.addAttribute(node)
        
        node = XMLNode(kind: .attribute)
        node.name = "origin"
        node.stringValue = origin.stringValue
        element.addAttribute(node)
        
        if self.visualType != .line {
            node = XMLNode(kind: .attribute)
            node.name = "size"
            node.stringValue = size.stringValue
            element.addAttribute(node)
        }

        node = XMLNode(kind: .attribute)
        node.name = "fill"
        node.stringValue = fill ? "true": "false"
        element.addAttribute(node)
        
        if color != nil {
            node = XMLNode(kind: .attribute)
            node.name = "color"
            node.stringValue = color!.stringValue
            element.addAttribute(node)
        }
        if lineWidth != nil {
            node = XMLNode(kind: .attribute)
            node.name = "lineWidth"
            node.stringValue = String(format:"%.3f",lineWidth!)
            element.addAttribute(node)
        }
        if phase != nil {
            node = XMLNode(kind: .attribute)
            node.name = "phase"
            node.stringValue = String(format:"%.3f",phase!)
            element.addAttribute(node)
        }
        if dash != nil {
            node = XMLNode(kind: .attribute)
            node.name = "dash"
            node.stringValue =  dash!.map{String(format:"%.3f",$0)}.joined(separator: ",")
            element.addAttribute(node)
        }
        
        if points != nil {
            for entry in points! {
                let child = XMLElement(name: "location")
                let childnode = XMLNode(kind: .attribute)
                childnode.name = "position"
                childnode.stringValue = entry.stringValue
                child.addAttribute(childnode)
                element.addChild(child) ;
            }
        }
        return element
    }
    
    init(element: XMLElement) throws {
        self.init()
        guard element.name == "visual" || element.name == "line" || element.name == "oval" else {
            throw NSError(domain: "Sequencer", code: 0, userInfo: [NSLocalizedDescriptionKey:"Invalid element name for 'Visual' \(element.name ?? "")"])
        }
        if element.name == "oval" {
            visualType = .oval
        }
        else if element.name == "line" {
            visualType = .line
        }
        else {
            let node = element.attribute(forName: "visualType")
            guard node!.stringValue != nil else {
                throw NSError(domain: "Sequencer", code: 0, userInfo: [NSLocalizedDescriptionKey:"No visualType specified for visual element"])
            }
            guard let temp = VisualType(rawValue: node!.stringValue!) else {
                throw NSError(domain: "Sequencer", code: 0, userInfo: [NSLocalizedDescriptionKey:"Invalid visualTYpe '\(node!.stringValue!)' specified for visual element"])
            }
            visualType = temp
        }

        try processAttributes(element: element)
        guard let children = element.children else {
            return
        }
        for child in children {
            if child.kind == .element {
                let entry = child as? XMLElement
                if entry != nil {
                    if entry!.name == "loc" || entry!.name == "location" {
                        var node = entry!.attribute(forName: "loc")
                        if node?.stringValue != nil {
                            let point = try CGPoint.pointFor(string: node!.stringValue!)
                            if points == nil {
                                points = [CGPoint]()
                            }
                            points?.append(point)
                        }
                        else {
                            node = entry!.attribute(forName: "position")
                            if node?.stringValue != nil {
                                let point = try CGPoint.pointFor(string: node!.stringValue!)
                                if points == nil {
                                    points = [CGPoint]()
                                }
                                points?.append(point)

                            }
                        }
                    }
                }
            }
        }
    }
    
    private mutating func processAttributes(element:XMLElement) throws {
        var node = element.attribute(forName: "origin")
        guard node?.stringValue != nil else {
            throw NSError(domain: "Sequencer", code: 0, userInfo: [NSLocalizedDescriptionKey:"Missing origin for visual"])
        }
        origin = try CGPoint.pointFor(string: node!.stringValue!)

        
        node = element.attribute(forName: "fill")
        fill = false
        if node?.stringValue != nil {
            fill = (node!.stringValue! == "yes") || (node!.stringValue! == "true")
        }
        if visualType == .oval {
            node = element.attribute(forName: "size")
            guard node?.stringValue != nil else {
                throw NSError(domain: "Sequencer", code: 0, userInfo: [NSLocalizedDescriptionKey:"Missing size for visual type oval"])
            }
            size = try CGSize.sizeFor(string: node!.stringValue!)
        }
        node = element.attribute(forName: "pattern")
        if node?.stringValue != nil {
            dash = node!.stringValue!.components(separatedBy: ",").map{ CGFloat(Double( $0.trimmingCharacters(in: .whitespaces)) ?? 0.0) }
        }
        node = element.attribute(forName: "dash")
        if node?.stringValue != nil {
            dash = node!.stringValue!.components(separatedBy: ",").map{ CGFloat(Double( $0.trimmingCharacters(in: .whitespaces)) ?? 0.0) }
        }
        
        node = element.attribute(forName: "phase")
        if node?.stringValue != nil {
            phase = Double(node?.stringValue!.trimmingCharacters(in: .whitespaces) ?? "0.0") ?? 0.0
        }

        node = element.attribute(forName: "lineWidth")
        if node?.stringValue != nil {
            lineWidth = Double(node?.stringValue!.trimmingCharacters(in: .whitespaces) ?? "0.0") ?? 0.0
        }
        node = element.attribute(forName: "color")
        if node?.stringValue != nil {
            color = CGColor.colorFor(string: node!.stringValue!)
        }
        
        node = element.attribute(forName: "light")
        if node?.stringValue != nil {
            lightName = node!.stringValue!
        }
    }
}

extension Visual {
    mutating func buildPath(_ transform:AffineTransform? = nil ) {
        var tempPath = NSBezierPath()
        switch visualType {
        case .line:
            tempPath.move(to: origin)

            if points != nil {
                for entry in points!{
                    tempPath.line(to: entry)
                }
            }
        case .oval:
            tempPath = NSBezierPath(ovalIn: NSRect(origin: origin, size: size))
        case .rect:
            tempPath = NSBezierPath(rect: NSRect(origin: origin, size: size))

        }
        if !fill {
            tempPath.lineWidth = lineWidth ?? NSBezierPath.defaultLineWidth
            if phase != nil && dash != nil && !(dash?.isEmpty ?? true) {
                tempPath.setLineDash(dash!, count: dash!.count, phase: phase!)
            }
        }
        if !tempPath.isEmpty {
            tempPath.close()
        }
        if transform != nil {
            tempPath.transform(using: transform! )
        }
        path = tempPath
        
    }
    func colorFor(data:[UInt8],lightType:LightType) -> NSColor {
        switch lightType {
        case .rgb,.grb:
            if lightType == .rgb {
                return NSColor(red: Double(data[0])/255.0, green: Double(data[1])/255.0, blue: Double(data[2])/255.0, alpha: 1.0)
            }
            else {
                return NSColor(red: Double(data[1])/255.0, green: Double(data[0])/255.0, blue: Double(data[2])/255.0, alpha: 1.0)
            }
        default:
            guard let color = color else { return NSColor.clear }
            let temp = color.setIntensity(value: Double(data[0])/255.0)
            return NSColor(cgColor: temp) ?? NSColor.clear
        }
    }
    
    func colorFor(pixelColor:PixelColor,lightType:LightType) -> NSColor {
        switch lightType {
        case .rgb,.grb:
            return pixelColor.nsColor
        default:
            guard let color = color else { return NSColor.clear }
            
            let temp = color.setIntensity(value: pixelColor.floatRed)
            
            return NSColor(cgColor: temp)!
 
        }
    }
}

struct VisualBundle {
    var name = "visualBundle"
    var bundleType = "none"
    var visuals = [Visual]()
}

extension VisualBundle : XMLProtocol {
    var xml: XMLElement {
        let element = XMLElement(name: "visualBundle")
        
        var node = XMLNode(kind: .attribute)
        node.name = "name"
        node.stringValue = name
        element.addAttribute(node)
        
        node = XMLNode(kind: .attribute)
        node.name = "bundleType"
        node.stringValue = bundleType
        element.addAttribute(node)
        
        for visual in visuals {
            element.addChild(visual.xml)
        }
        return element
    }
    
    init(element: XMLElement) throws {
        self.init()
        guard element.name == "visualBundle"  || element.name == "visualGroup" else {
            throw NSError(domain: "Sequencer", code: 0, userInfo: [NSLocalizedDescriptionKey:"Invalid element '\(element.name ?? "")' for visualBundle"])
        }
        
        var node = element.attribute(forName: "name")
        guard node?.stringValue != nil else {
            throw NSError(domain: "Sequencer", code: 0, userInfo: [NSLocalizedDescriptionKey:"Missing name  for visualBundle"])
        }
        self.name = node!.stringValue!
        
        node = element.attribute(forName: "bundleType")
        guard node?.stringValue != nil else {
            throw NSError(domain: "Sequencer", code: 0, userInfo: [NSLocalizedDescriptionKey:"Missing bundle type  for visualBundle: \(name)"])
        }
        self.bundleType = node!.stringValue!
        
        guard let children = element.children else { return }
        for child in children {
            if child.kind == .element {
                let entry = child as? XMLElement
                if entry != nil {
                    if entry!.name == "oval" || entry!.name == "line" || entry!.name == "visual" {
                        var visual = try Visual(element: entry!)
                        
                        visual.buildPath()
                        visuals.append( visual )
                    }
                }
            }
        }
    }
    
    
}

func processVisualBundles(url:URL) throws -> [String:VisualBundle] {
    let xmldoc = try XMLDocument(contentsOf: url)
    var rvalue = [String:VisualBundle]()
    
    guard let root = xmldoc.rootElement() else {
        throw NSError(domain: "Sequencer", code: 0, userInfo: [NSLocalizedDescriptionKey:"Missing root element in visualBundle file: \(url.path())"])
    }
    guard root.name == "visualGroups"  || root.name == "visualBundles" else {
            throw NSError(domain: "Sequencer", code: 0, userInfo: [NSLocalizedDescriptionKey:"Invalid visual group file, root element name for visualGroup is 'visualGroups' and visualBundle is 'visualBundles', found \(root.name ?? "")"])
    }
    if root.name == "visualGroups" {
        for element  in root.elements(forName: "visualGroup") {
            let bundle = try VisualBundle(element: element)
            rvalue[bundle.name] = bundle
        }
    }
    else {
        for element  in root.elements(forName: "visualBundle") {
            let bundle = try VisualBundle(element: element)
            rvalue[bundle.name] = bundle
        }
    }
    return rvalue 
}
