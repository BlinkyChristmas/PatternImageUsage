// Copyright © 2024 Charles Kerr. All rights reserved.

import Foundation
extension Float {
    var milliSeconds:Int {
        Int((self * 1000.0).rounded())
    }
}
extension Double {
    var milliSeconds:Int {
        Int((self * 1000.0).rounded())
    }
}

extension Int {
    static func milliFromString(floatstring:String) -> Int? {
        return Double(floatstring)?.milliSeconds
    }
}
