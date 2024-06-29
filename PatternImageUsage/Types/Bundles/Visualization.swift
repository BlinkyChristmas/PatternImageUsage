// Copyright © 2024 Charles Kerr. All rights reserved.

import Foundation

struct Visualization {
    
    var dataLocation:String?
    var visualItems = [VisualItem]()
    var name:String?
    var visualScale = 1.0
    var visualOrigin = NSPoint.zero
    var visualSize = NSSize.zero

    
}

extension Visualization {
    init(url:URL,bundles:[String:LightBundle]) throws {
        self.init()
        let xmldoc = try XMLDocument(contentsOf: url)
        guard let root = xmldoc.rootElement() else {
            throw NSError(domain: "Sequencer", code: 0, userInfo: [NSLocalizedDescriptionKey:"File has no root element: \(url.path())"])
        }
        guard root.name == "visualization" else {
            throw NSError(domain: "Sequencer", code: 0, userInfo: [NSLocalizedDescriptionKey:"Invalid root element '\(root.name ?? "" )' for \(url.path())"])
        }
        var node = root.attribute(forName: "data")
        guard node?.stringValue != nil else {
            throw NSError(domain: "Sequencer", code: 0, userInfo: [NSLocalizedDescriptionKey:"Visualization file is missing a location attribute for \(url.path())"])
        }
        dataLocation = node!.stringValue!
        name = url.deletingPathExtension().lastPathComponent
        node = root.attribute(forName: "name")
        if node?.stringValue != nil {
            name = node?.stringValue
        }
        
        node = root.attribute(forName: "visualScale")
        if node?.stringValue != nil {
            let temp = Double(node!.stringValue!)
            if temp != nil {
                visualScale = temp!
            }
        }
        node = root.attribute(forName: "visualOrigin")
        if node?.stringValue != nil {
            let temp = try? NSPoint.pointFor(string: node!.stringValue!)
            if temp != nil {
                visualOrigin = temp!
            }
        }
        node = root.attribute(forName: "visualSize")
        if node?.stringValue != nil {
            let temp = try? NSSize.sizeFor(string: node!.stringValue!)
            if temp != nil {
                visualSize = temp!
            }
        }

        for child in root.elements(forName: "visualItem") {
            var temp = try VisualItem(element: child)
            temp.updateBundle(bundles: bundles)
            visualItems.append(temp)
        }
    }
}
