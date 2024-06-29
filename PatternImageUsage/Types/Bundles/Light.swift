// Copyright © 2024 Charles Kerr. All rights reserved.

import Foundation
import AppKit

enum LightType : String,CustomStringConvertible {
    case rgb,grb,strobe,onoff,intensity
    
    var channels:Int {
        switch self {
        case .grb,.rgb:
            return 3
        default:
            return 1 ;
        }
    }
    var description: String {
        return self.rawValue
    }
}

struct Light {
    var lightType = LightType.rgb
    var name = "Light"
    var imageOrigin = CGPoint.zero
    var offset = 0
    var visuals = [Visual]()
}

extension Light : XMLProtocol {
    var xml: XMLElement {
        let element = XMLElement(name: "light")
        
        var node = XMLNode(kind: .attribute)
        node.name = "type"
        node.stringValue = lightType.description
        element.addAttribute(node)

        
        node = XMLNode(kind: .attribute)
        node.name = "name"
        node.stringValue = name
        element.addAttribute(node)
        
        node = XMLNode(kind:.attribute)
        node.name = "imageOrigin"
        node.stringValue = imageOrigin.stringValue
        element.addAttribute(node)
        
        node = XMLNode(kind:.attribute)
        node.name = "offset"
        node.stringValue = String(offset)
        element.addAttribute(node)
        
        for entry in visuals {
            element.addChild(entry.xml)
        }
        return element
    }
    
    init(element: XMLElement) throws {
        self.init()
        guard element.name == "lightSource" || element.name == "light" else {
            throw NSError(domain: "Sequencer", code: 0, userInfo: [NSLocalizedDescriptionKey:"Invalid element for 'Light' \(element.name ?? "")"])
        }
        
        var node = element.attribute(forName: "type")
        guard node?.stringValue != nil else {
            throw NSError(domain: "Sequencer", code: 0, userInfo: [NSLocalizedDescriptionKey:"Missing type 'Light'"])
        }
        guard let temp = LightType(rawValue:node!.stringValue!) else {
            throw NSError(domain: "Sequencer", code: 0, userInfo: [NSLocalizedDescriptionKey:"Invalid type '\(node!.stringValue!)' for 'Light' "])
        }
        lightType = temp
  
        node = element.attribute(forName: "name")
        guard node?.stringValue != nil else {
            throw NSError(domain: "Sequencer", code: 0, userInfo: [NSLocalizedDescriptionKey:"Missing name for 'Light'"])
        }
        name = node!.stringValue!
        
        node = element.attribute(forName: "origin")
        if node?.stringValue == nil {
            node = element.attribute(forName: "imageOrigin")
            /*
            if node?.stringValue == nil {
                 throw NSError(domain: "Sequencer", code: 0, userInfo: [NSLocalizedDescriptionKey:"Missing image origin for 'Light'"])
            }
             */
        }
        if node?.stringValue != nil {
            imageOrigin = try CGPoint.pointFor(string: node!.stringValue!)
        }
        
        guard let children = element.children else { return }
        for entry in children {
            if entry.kind == .element {
                let child = entry as? XMLElement
                if child != nil {
                    if child!.name == "visual" {
                        var temp = try Visual(element: child!)
                        temp.buildPath()
                        visuals.append(temp)
                    }
                }
            }
        }
    }
}

extension Light {
    func drawLight(data:[UInt8]) {
        guard !visuals.isEmpty else {  return }
        for visual in visuals {
            if visual.path != nil {
                
                let color = visual.colorFor(data:Array(data[data.startIndex+self.offset..<data.startIndex+self.offset+self.lightType.channels]), lightType: self.lightType)
                
                if visual.fill {
                    color.setFill()
                    
                    visual.path!.fill()
                }
                else {
                    color.setStroke()
                    visual.path!.stroke()
                }
            }
        }
    }
    func drawLight(pixel:PixelColor){
        guard !visuals.isEmpty else {  return }
        for visual in visuals {
            if visual.path != nil {
                
                let color = visual.colorFor(pixelColor: pixel, lightType: self.lightType)
                
                if visual.fill {
                    color.setFill()
                    
                    visual.path!.fill()
                }
                else {
                    color.setStroke()
                    
                    visual.path!.stroke()
                }
            }
        }

    }
    mutating func buildPaths(_ transform:AffineTransform? = nil) {
        for index in 0..<visuals.count  {
            visuals[index].buildPath(transform)
        }
    }
    func dataForPixelColor(pixelColor:PixelColor) -> Data {
        var data = Data()
        switch self.lightType {
        case .rgb,.grb:
            data = Data(repeating: 0, count: 3)
            data[0] = self.lightType == .rgb ? pixelColor.red : pixelColor.green
            data[1] = self.lightType == .rgb ? pixelColor.green : pixelColor.red
            data[2] = pixelColor.blue
        case .intensity:
            data = Data(repeating: 0, count: 1)
            data[0] = pixelColor.red
        case .onoff,.strobe:
            data = Data(repeating: 0, count: 1)
            data[0] = pixelColor.red > 128 ? 255 : 0
        }
        return data
    }

}

// =======================================================================
// LightBundle
// ========================================================================
struct LightBundle {
    var name = "LightBundle"
    var size = CGSize.zero
    var imageDirectory:String?
    var patternDirectory:String?
    var lights = [Light]()
}

extension LightBundle : XMLProtocol {
    var xml: XMLElement {
        let element = XMLElement(name: "lightBundle")
        var node = XMLNode(kind: .attribute)
        node.name = "name"
        node.stringValue = name
        element.addAttribute(node)
        
        node = XMLNode(kind: .attribute)
        node.name = "size"
        node.stringValue = size.stringValue
        element.addAttribute(node)
        
        if imageDirectory != nil {
            node = XMLNode(kind: .attribute)
            node.name = "imageDirectory"
            node.stringValue = imageDirectory
            element.addAttribute(node)
        }
        
        if patternDirectory != nil {
            node = XMLNode(kind: .attribute)
            node.name = "patternDirectory"
            node.stringValue = patternDirectory
            element.addAttribute(node)
        }
        

        
        for light in lights {
            element.addChild(light.xml)
        }
        return element
    }
    
    init(element: XMLElement) throws {
        self.init()
        guard element.name == "lightBundle" || element.name == "lightGroup" else {
            throw NSError(domain: "Sequencer", code: 0, userInfo: [NSLocalizedDescriptionKey:"Invalid element for 'lightBundle': \(element.name ?? "")"])
        }
        var node = element.attribute(forName: "name")
        guard node?.stringValue != nil else {
            throw NSError(domain: "Sequencer", code: 0, userInfo: [NSLocalizedDescriptionKey:"Missing name for 'lightBundle':"])
        }
        name = node!.stringValue!
        
        node = element.attribute(forName: "size")
        guard node?.stringValue != nil else {
            throw NSError(domain: "Sequencer", code: 0, userInfo: [NSLocalizedDescriptionKey:"Missing size for 'lightBundle': \(name)"])
        }
        do {
            size = try CGSize.sizeFor(string: node!.stringValue!)
        }
        catch{
            throw NSError(domain: "Sequencer", code: 0, userInfo: [NSLocalizedDescriptionKey:"Invalid size '\(node!.stringValue!)'  for 'lightBundle': \(name)"])

        }
        
        node = element.attribute(forName: "imageDirectory")
        if node?.stringValue != nil {
            self.imageDirectory = node?.stringValue
        }

        node = element.attribute(forName: "patternDirectory")
        if node?.stringValue != nil {
            self.patternDirectory = node?.stringValue
        }

        guard let children = element.children else {
            return
        }
        for child in children {
            if child.kind == .element {
                let entry = child as? XMLElement
                if entry != nil {
                    if entry?.name == "lightSource" || entry?.name == "light" {
                        lights.append(try Light(element: entry!))
                    }
                }
            }
        }
        self.updateOffsets()

    }
}

extension LightBundle {
    func lightIndexFor(name:String) -> [Light].Index {
        for (index,entry) in lights.enumerated() {
            if entry.name == name {
                return index
            }
        }
        return lights.endIndex
    }
    var endIndex:[Light].Index {
        return lights.endIndex
    }
    mutating func updateOffsets() {
        var offset = 0
        for index in 0..<lights.count {
            lights[index].offset = offset
            offset += lights[index].lightType.channels 
        }
    }
    var count:Int {
        return lights.reduce(0, {$0 + $1.lightType.channels})
    }
    
    var bundleImageDirectory:String {
        if imageDirectory == nil {
            return name
        }
        return imageDirectory!
    }
    
    var bundlePatternDirectory:String {
        if patternDirectory == nil {
            return name
        }
        return patternDirectory!
    }
    
    func drawLights(colors:[PixelColor]) {
        for (index,light) in lights.enumerated() {
            light.drawLight(pixel: colors[index])
        }
    }
    
}


func processBundles(url:URL) throws -> [String:LightBundle] {
    return try processLightGroup(url: url)
}

func processLightGroup(url:URL) throws -> [String:LightBundle] {
    let xmldoc = try XMLDocument(contentsOf: url)
    var rvalue = [String:LightBundle]()
    guard let root = xmldoc.rootElement() else {
        throw NSError(domain: "Sequencer", code: 0, userInfo: [NSLocalizedDescriptionKey:"Missing root element: \(url.path())"])
    }
    guard root.name == "lightGroups" || root.name == "lightBundles" else {
        throw NSError(domain: "Sequencer", code: 0, userInfo: [NSLocalizedDescriptionKey:"Invalid light group/bundle file, root element name for lightGroups is 'lightGroups' and bundle is 'lighBundles', found \(root.name ?? "")"])
    }
    if root.name == "lightGroups" {
        for element  in root.elements(forName: "lightGroup") {
            let bundle = try LightBundle(element: element)
            rvalue[bundle.name] = bundle
        }
    }
    else {
        for element  in root.elements(forName: "lightBundle") {
            let bundle = try LightBundle(element: element)
            rvalue[bundle.name] = bundle
        }

    }
    return rvalue
}
