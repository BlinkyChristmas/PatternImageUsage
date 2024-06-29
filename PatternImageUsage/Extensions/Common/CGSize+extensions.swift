// Copyright © 2024 Charles Kerr. All rights reserved.

import Foundation

extension CGSize {
    
    var stringValue:String {
        return String(format:"%.3f,%.3f", self.width,self.height)
    }
    
    static func sizeFor(string:String) throws -> CGSize {
        let values = string.components(separatedBy: ",").map{ $0.trimmingCharacters(in: .whitespaces) }
        guard values.count == 2 else {
            throw NSError(domain: "Blinky", code: 0, userInfo: [NSLocalizedDescriptionKey:"Invalid format for size: \(string) "])
        }
        guard let width = Double(values[0]), let height = Double(values[1]) else {
            throw NSError(domain: "Blinky", code: 0, userInfo: [NSLocalizedDescriptionKey:"Invalid format for size: \(string) "])
        }
        return CGSize(width: width, height: height)
    }
}
