// Copyright © 2024 Charles Kerr. All rights reserved.

import Foundation

struct VisualItem {
    var name = "visualItem"
    var bundleType = "none"
    var scale = 1.0
    var origin = CGPoint.zero
    var offset = 0
    var lightBundle:LightBundle?
}

extension VisualItem : XMLProtocol {
    var xml: XMLElement{
        let element = XMLElement(name:"visualItem")
        
        var node = XMLNode(kind: .attribute)
        node.name = "name"
        node.stringValue = name
        element.addAttribute(node)
        
        node = XMLNode(kind: .attribute)
        node.name = "bundleType"
        node.stringValue = bundleType
        element.addAttribute(node)
        
        node = XMLNode(kind: .attribute)
        node.name = "scale"
        node.stringValue = String(format: ".%3f", scale)
        element.addAttribute(node)
        
        node = XMLNode(kind: .attribute)
        node.name = "origin"
        node.stringValue = origin.stringValue
        element.addAttribute(node)

        node = XMLNode(kind: .attribute)
        node.name = "offset"
        node.stringValue = String(offset)
        element.addAttribute(node)
        
        return element
    }
    
    init(element: XMLElement) throws {
        self.init()
        guard element.name == "visualItem" else {
            throw NSError(domain: "Sequencer", code: 0, userInfo: [NSLocalizedDescriptionKey:"Invalid element for 'visualItem': \(element.name ?? "")"])
        }
        
        var node = element.attribute(forName: "name")
        guard node?.stringValue != nil else {
            throw NSError(domain: "Sequencer", code: 0, userInfo: [NSLocalizedDescriptionKey:"Missing name for 'visualItem'"])
        }
        name = node!.stringValue!
        
        node = element.attribute(forName: "bundleType")
        guard node?.stringValue != nil else {
            throw NSError(domain: "Sequencer", code: 0, userInfo: [NSLocalizedDescriptionKey:"Missing bundleType for 'visualItem' \(name)"])
        }
        bundleType = node!.stringValue!
        
        node = element.attribute(forName: "scale")
        if node?.stringValue != nil {
            guard let temp  = Double(node!.stringValue!) else {
                throw NSError(domain: "Sequencer", code: 0, userInfo: [NSLocalizedDescriptionKey:"Invalid scale '\(node!.stringValue!)' for 'visualItem' \(name)"])
            }
            scale = temp
        }
        
        node = element.attribute(forName: "origin")
        guard node?.stringValue != nil else {
            throw NSError(domain: "Sequencer", code: 0, userInfo: [NSLocalizedDescriptionKey:"Missing origin for 'visualItem' \(name)"])
        }
        do {
            origin = try CGPoint.pointFor(string: node!.stringValue!)
        }
        catch {
            throw NSError(domain: "Sequencer", code: 0, userInfo: [NSLocalizedDescriptionKey:"Invalid origin '\(node!.stringValue!)' for 'visualItem' \(name)"])
        }
        
        node = element.attribute(forName: "offset")
        guard node?.stringValue != nil else {
            throw NSError(domain: "Sequencer", code: 0, userInfo: [NSLocalizedDescriptionKey:"Missing offset for 'visualItem' \(name)"])
        }
        guard let tempoffset = Int(node!.stringValue!) else {
            throw NSError(domain: "Sequencer", code: 0, userInfo: [NSLocalizedDescriptionKey:"Invalid offset '\(node!.stringValue!)' for 'visualItem' \(name)"])
        }
        offset = tempoffset 
    }
}

extension VisualItem {
    func draw(frame:[UInt8]){
        guard let bundle = lightBundle else {  return }
        guard !bundle.lights.isEmpty else {  return }
        for light in bundle.lights {
            
            light.drawLight(data: frame)
        }
    }
    func draw(pixelFrame:[PixelColor]){
        guard let bundle = lightBundle else {  return }
        guard !bundle.lights.isEmpty else {  return }
        for (index,light) in bundle.lights.enumerated() {
            
            light.drawLight(pixel: pixelFrame[index])
        }

    }
    mutating func updateBundle(bundles:[String:LightBundle]) {
        //Swift.print("looking for \(self.bundleType) out of \(bundles.count) bundles")
        self.lightBundle = bundles[self.bundleType]
        // We need to set our transforms
        var transform = AffineTransform.init(translationByX: origin.x, byY: origin.y)
        if scale != 1.0 {
            transform.scale(scale)
        }
        guard self.lightBundle != nil else { return }
        for index in 0..<self.lightBundle!.lights.count{
            self.lightBundle!.lights[index].buildPaths(transform)
        }

    }
}

