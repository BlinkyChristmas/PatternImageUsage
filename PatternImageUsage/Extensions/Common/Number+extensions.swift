//Copyright © 2023 Charles Kerr. All rights reserved.
import Foundation
extension BinaryInteger  {
    /// Obtain the data representation of the value
    public var data: Data {
        return withUnsafeBytes(of: self) { Data($0) }
    }
    
    public var milliSeconds: Double {
        Double(self)/1000.0
    }
    public var milliString:String {
        String(format:"%.3f",self.milliSeconds)
    }
    
}
extension FloatingPoint  {
    /// Obtain the data representation of the value
    public var data: Data {
        return withUnsafeBytes(of: self) { Data($0) }
    }
}

extension Array where Element:FixedWidthInteger {
    /// Obtain the data representation of the array
    public var data:Data {
       return self.withUnsafeBufferPointer {Data(buffer: $0)}
    }
}
