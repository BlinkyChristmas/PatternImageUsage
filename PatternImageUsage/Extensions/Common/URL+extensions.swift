//Copyright © 2023 Charles Kerr. All rights reserved.

import Foundation
import ImageIO

extension URL {
    public var size:Int {
        guard let size =  try? self.resourceValues(forKeys:[.fileSizeKey]).fileSize else {
            return 0
        }
        return size
    }
    public var isHidden:Bool {
        guard let value = try? self.resourceValues(forKeys: [.isHiddenKey]).isHidden else {
            return true
        }
        return value
    }
    public var isReqularFile:Bool {
        guard let value = try? self.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile else {
            return false
        }
        return value
    }

    public var isDirectory:Bool {
        guard let value = try? self.resourceValues(forKeys: [.isDirectoryKey]).isDirectory else {
            return false
        }
        return value
    }

    public var isReadable:Bool {
        guard let value = try? self.resourceValues(forKeys: [.isReadableKey]).isReadable else {
            return false
        }
        return value
    }


    public var exist:Bool {
        guard let status =  try? self.checkResourceIsReachable() else {
            return false
        }
        return status
    }
    public var securityData:Data? {
        guard self.isFileURL else {return nil}
        return try? self.bookmarkData(options: .withSecurityScope,includingResourceValuesForKeys: nil,relativeTo: nil)
    }
    
    public var image:CGImage? {
        guard let imageSource = CGImageSourceCreateWithURL(self as CFURL, nil) else {
            return nil
        }
        return CGImageSourceCreateImageAtIndex(imageSource, 0, nil)
    }

}
