// Copyright © 2024 Charles Kerr. All rights reserved.

import Foundation

class ItemEffect : NSObject,Codable {
    
    @objc dynamic var gridName:String?
    @objc dynamic var pattern:String?
    @objc dynamic var startTime = 0
    @objc dynamic var endTime = 0
    @objc dynamic var effectLayer = 0
    @objc dynamic var width:Int {
        return endTime - startTime
    }
    init(gridName: String? = nil, pattern: String? = nil, startTime: Int = 0, endTime: Int = 0, effectLayer: Int = 0) {
        self.gridName = gridName
        self.pattern = pattern
        self.startTime = startTime
        self.endTime = endTime
        self.effectLayer = effectLayer
    }
    override var description: String {
        String(format: "Pattern: %@, Grid: %@, Span: %.3f-%.3f, Layer: %u",pattern ?? "", gridName ?? "", startTime.milliSeconds,endTime.milliSeconds,effectLayer)
    }
}
// =========== NSCopying
extension ItemEffect : NSCopying {
    func copy(with zone: NSZone? = nil) -> Any {
        ItemEffect(gridName: self.gridName, pattern: self.pattern, startTime: self.startTime, endTime: self.endTime, effectLayer: self.effectLayer)
    }
}

// ========== XML Support
extension ItemEffect {
    var xml:XMLElement {
        let element = XMLElement(name: "effect")
        
        var node = XMLNode(kind: .attribute)
        node.name = "pattern"
        node.stringValue = self.pattern
        element.addAttribute(node)

        node = XMLNode(kind: .attribute)
        node.name = "layer"
        node.stringValue = String(self.effectLayer)
        element.addAttribute(node)

        node = XMLNode(kind: .attribute)
        node.name = "gridName"
        node.stringValue = self.gridName ?? ""
        element.addAttribute(node)

        node = XMLNode(kind: .attribute)
        node.name = "startTime"
        node.stringValue = startTime.milliString
        element.addAttribute(node)

        node = XMLNode(kind: .attribute)
        node.name = "endTime"
        node.stringValue = endTime.milliString
        element.addAttribute(node)
        return element
    }
    convenience init(element:XMLElement) throws {
        self.init()
        guard element.name == "effect" else {
            throw GeneralError(errorMessage: "Invalid element name for ItemEffect: \(element.name ?? "")")
        }
        
        var node = element.attribute(forName: "pattern")
        if node?.stringValue == nil {
            throw GeneralError(errorMessage: "Effect element missing pattern attribute value")
        }
        self.pattern = node!.stringValue!
        
        node = element.attribute(forName: "layer")
        if node?.stringValue == nil {
            throw GeneralError(errorMessage: "Effect element missing layer attribute value")
        }
        guard let layer = Int(node!.stringValue!) else {
            throw GeneralError(errorMessage: "Effect element had invalid layer attribute value: \(node!.stringValue!)")
        }
        self.effectLayer = layer
        
        node = element.attribute(forName: "gridName")
        if node?.stringValue == nil {
            // Might have the old tag
            node = element.attribute(forName: "grid")
        }
        if node?.stringValue == nil {
            throw GeneralError(errorMessage: "Effect element missing gridName attribute value")
        }
        self.gridName = node!.stringValue!

        node = element.attribute(forName: "startTime")
        if node?.stringValue == nil {
            throw GeneralError(errorMessage: "Effect element missing startTime attribute value")
        }
        guard let tstartTime = Double(node!.stringValue!) else {
            throw GeneralError(errorMessage: "Effect element had invalid startTime attribute value: \(node!.stringValue!)")
        }
        self.startTime = tstartTime.milliSeconds
        
        node = element.attribute(forName: "endTime")
        if node?.stringValue == nil {
            throw GeneralError(errorMessage: "Effect element missing endTime attribute value")
        }
        guard let tendTime = Double(node!.stringValue!) else {
            throw GeneralError(errorMessage: "Effect element had invalid endTime attribute value: \(node!.stringValue!)")
        }
        self.endTime = tendTime.milliSeconds
        //Swift.print(" startTime: \(self.startTime)  endTime: \(self.endTime)")
    }
}


// ========== Covering support
extension ItemEffect {
    func isCoveredOrWillCover( effect:ItemEffect) -> Bool {
        guard effect.effectLayer == self.effectLayer else { return false}  // Get rid of the ones that are not on the same layer
        if (effect.startTime >=  self.startTime) && (effect.endTime <= self.endTime) || (effect.startTime <=  self.startTime) && (effect.endTime >= self.endTime) {
            return true
        }
        return false

    }
}
