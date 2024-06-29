// Copyright © 2024 Charles Kerr. All rights reserved.

import Foundation

extension CGPoint {
    
    var stringValue:String {
        return String(format:"%.3f,%.3f", self.x,self.y)
    }
    
    static func pointFor(string:String) throws -> CGPoint {
        let values = string.components(separatedBy: ",").map{ $0.trimmingCharacters(in: .whitespaces) }
        guard values.count == 2 else {
            throw NSError(domain: "Blinky", code: 0, userInfo: [NSLocalizedDescriptionKey:"Invalid format for point: \(string) "])
        }
        guard let x = Double(values[0]), let y = Double(values[1]) else {
            throw NSError(domain: "Blinky", code: 0, userInfo: [NSLocalizedDescriptionKey:"Invalid format for point: \(string) "])
        }
        return CGPoint(x: x, y: y)
    }
}
