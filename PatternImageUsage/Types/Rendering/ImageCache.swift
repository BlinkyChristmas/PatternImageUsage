// Copyright © 2024 Charles Kerr. All rights reserved.

import Foundation
import AppKit

class ImageCache : NSObject {
    var images = [String:NSBitmapImageRep]()
    func reset() {
        images.removeAll()
    }
    func imageFor(base:URL,key:String) throws -> NSBitmapImageRep  {
        if images.keys.contains(key) {
            return images[key]!
        }
        else {
            let data = try Data(contentsOf: base.appending(path: key))
            guard let rep = NSBitmapImageRep(data: data) else { throw GeneralError(errorMessage: "Unable to load image \(base.appending(path: key).path())")}
            images[key] = rep
            return rep
        }
    }
}
