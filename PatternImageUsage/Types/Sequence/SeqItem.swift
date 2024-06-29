// Copyright © 2024 Charles Kerr. All rights reserved.

import Foundation
class SeqItem : NSObject,Codable {
    
    @objc dynamic var effects = [ItemEffect]()
    
    @objc dynamic var name:String?
    @objc dynamic var bundleType:String?
    @objc dynamic var visualOrigin = NSPoint.zero
    @objc dynamic var visualScale = 1.0
    @objc dynamic var dataOffset = 0

    
    init(effects: [ItemEffect] = [ItemEffect](), name: String? = nil, bundleType: String? = nil, visualOrigin: NSPoint = NSPoint.zero, visualScale: Double = 1.0, dataOffset: Int = 0) {
        self.effects = effects
        self.name = name
        self.bundleType = bundleType
        self.visualOrigin = visualOrigin
        self.dataOffset = dataOffset
    }
}

// =========== NSCopying
extension SeqItem : NSCopying {
    func copy(with zone: NSZone? = nil) -> Any {
        SeqItem(effects: self.effects.map{ $0.copy() as! ItemEffect}, name: self.name, bundleType: self.bundleType, visualOrigin: self.visualOrigin, visualScale: self.visualScale, dataOffset: self.dataOffset)
    }
}

// =========== XML
extension SeqItem {
    var xml:XMLElement {
        let element = XMLElement(name: "sequenceItem")
        
        var node = XMLNode(kind: .attribute)
        node.name = "name"
        node.stringValue = self.name
        element.addAttribute( node)
        
        node = XMLNode(kind: .attribute)
        node.name = "bundleType"
        node.stringValue = self.bundleType
        element.addAttribute( node)
        
        node = XMLNode(kind: .attribute)
        node.name = "visualOrigin"
        node.stringValue = self.visualOrigin.stringValue
        element.addAttribute( node)
        
        node = XMLNode(kind: .attribute)
        node.name = "visualScale"
        node.stringValue = String(self.visualScale)
        element.addAttribute( node)
        

        node = XMLNode(kind: .attribute)
        node.name = "dataOffset"
        node.stringValue = String(self.dataOffset)
        element.addAttribute( node)
        
        for effect in effects.sorted(by: { lhs, rhs in
            guard lhs.startTime <= rhs.startTime else { return false }
            guard lhs.startTime == rhs.startTime else { return true}
            guard lhs.endTime >= rhs.endTime else { return true }
            guard lhs.endTime == rhs.endTime else { return false }
            guard lhs.effectLayer >= rhs.effectLayer else { return true }
            return false
        }) {
            element.addChild(effect.xml)
        }
        return element
    }
    
    convenience init(element:XMLElement) throws {
        self.init()
        guard element.name == "sequenceItem" else {
            throw GeneralError(errorMessage: "Invalid element name for sequenceItem: \(element.name ?? "")")
        }
        var node = element.attribute(forName: "name")
        guard node?.stringValue != nil else {
            throw GeneralError(errorMessage: "SequenceItem element missing name attribute/value")
        }
        name = node!.stringValue!
        
        node = element.attribute(forName: "bundleType")
        if node?.stringValue == nil {
            node = element.attribute(forName: "source")
        }
        guard node?.stringValue != nil else {
            throw GeneralError(errorMessage: "SequenceItem element missing name attribute/value")
        }
        bundleType = node!.stringValue!
        
        node = element.attribute(forName: "visualOrigin")
        if node?.stringValue != nil {
            visualOrigin = try NSPoint.pointFor(string: node!.stringValue!)
        }
        node = element.attribute(forName: "visualScale")
        if node?.stringValue != nil  {
            guard let value = Double(node!.stringValue!) else {
                throw GeneralError(errorMessage: "SequenceItem element has invalid visiual scale value: \(node!.stringValue!)")
            }
            visualScale = value
        }
        node = element.attribute(forName: "dataOffset")
        if node?.stringValue != nil  {
            guard let value = Int(node!.stringValue!) else {
                throw GeneralError(errorMessage: "SequenceItem element has invalid dataOffset value: \(node!.stringValue!)")
            }
            dataOffset = value
        }
        
        for child in element.elements(forName: "effect") {
            effects.append(try ItemEffect(element: child))
        }
    }
}
