// Copyright © 2024 Charles Kerr. All rights reserved.

import Foundation

class TransitionType : NSObject {
    enum PixelEffectType : String, CaseIterable {
        case none,add,blend,color,random,shimmer,sparkle,twinkle,diminish
    }
    var pixelEffect = PixelEffectType.none
    var startImage:String?
    var endImage:String?
    var maskImage:String?
    var startOrigin = NSPoint.zero
    var endOrigin = NSPoint.zero
    var maskOrigin = NSPoint.zero

    override var description: String {
        return "effect: \(pixelEffect.rawValue) startImage: \(startImage ?? "") endImage: \(endImage ?? "") maskImage: \(maskImage ?? "") startOrigin: \(startOrigin) endOrigin: \(endOrigin) maskOrigin: \(maskOrigin)"
    }
}

extension TransitionType {
    convenience init(element:XMLElement) throws {
        self.init()
        guard let name = element.name else { throw GeneralError(errorMessage: "Transition element had no name") }
        guard let type = PixelEffectType(rawValue: name) else { throw GeneralError(errorMessage: "Invalid transisiton effect: \(name)")}
        pixelEffect = type
        var node = element.attribute(forName: "endImage")
        guard node?.stringValue != nil else {
            throw GeneralError(errorMessage: "Missing endImage attribute value for \(pixelEffect.rawValue)")
        }
        endImage = node?.stringValue
        node = element.attribute(forName: "maskImage")
        guard node?.stringValue != nil else {
            throw GeneralError(errorMessage: "Missing maskImage attribute value for \(pixelEffect.rawValue)")
        }
        maskImage = node?.stringValue
        node = element.attribute(forName: "startImage")
        guard node?.stringValue != nil else {
            throw GeneralError(errorMessage: "Missing startImage attribute value for \(pixelEffect.rawValue)")
        }
        startImage = node?.stringValue
        node = element.attribute(forName: "startOrigin")
        if node?.stringValue != nil  {
            startOrigin = try NSPoint.pointFor(string: node!.stringValue!)
        }
        node = element.attribute(forName: "endOrigin")
        if node?.stringValue != nil {
            endOrigin = try NSPoint.pointFor(string: node!.stringValue!)
        }
        node = element.attribute(forName: "maskOrigin")
        if node?.stringValue != nil {
            maskOrigin = try NSPoint.pointFor(string: node!.stringValue!)
        }
    }
}

func loadPattern(url:URL) throws -> [[TransitionType]]{
    var rvalue = [[TransitionType]]()
    
    let doc = try XMLDocument(contentsOf: url,options: .documentTidyXML)
    guard let root = doc.rootElement() else { throw GeneralError(errorMessage: "Invalid pattern file for \(url.path())")}
    guard  (root.name ?? "") == "pattern" else { throw GeneralError(errorMessage: "Invalid pattern file for \(url.path())")}
    let transistions = root.elements(forName: "transition")
    for trans in transistions {
        let children = trans.children
        var effectChanges = [TransitionType]()
        for entry in children!{
            let child = entry as? XMLElement
            if child?.name != nil {
                let type = TransitionType.PixelEffectType(rawValue: child!.name!)
                if type != nil {
                    effectChanges.append(try TransitionType(element: child!))
                }
            }
        }
        rvalue.append(effectChanges)
    }
    return rvalue
}
