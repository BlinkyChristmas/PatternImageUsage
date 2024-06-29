//Copyright © 2023 Charles Kerr. All rights reserved.

import Foundation
extension ContiguousBytes {
    func objects<T>() -> [T] { withUnsafeBytes { .init($0.bindMemory(to: T.self)) } }
    
    public var int8Array   : [Int8]   { objects() }
    public var uInt8Array  : [UInt8]  { objects() }
    public var int16Array  : [Int16]  { objects() }
    public var uInt16Array : [UInt16] { objects() }
    public var int32Array  : [Int32]  { objects() }
    public var uInt32Array : [UInt32] { objects() }
    public var int64Array  : [Int64]  { objects() }
    public var uInt64Array : [UInt64] { objects() }
    public var intArray  : [Int]  { objects() }
    public var uIntArray : [UInt] { objects() }
}
