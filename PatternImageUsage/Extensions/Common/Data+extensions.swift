//Copyright © 2023 Charles Kerr. All rights reserved.

import Foundation
import ImageIO
extension Data {
    public var securityBookmark:URL? {
        let (url,_) = self.obtainSecurity()
        return url
    }
    
    public func obtainSecurity() -> (URL?,Bool) {
        var isStale = false
        let url =  try? URL(resolvingBookmarkData: self, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
        return (url,isStale)
    }
    
    public func createImage(width:Int,height:Int,hasAlpha:Bool = true,pixelDepth:Int = 16) -> CGImage? {
        guard let provider = CGDataProvider(data:self as CFData) else {
            return nil
        }
        let bitComponent = pixelDepth == 16 ? 5 : 8
        let orderInfo = pixelDepth==16 ? CGBitmapInfo.byteOrder16Little.rawValue : CGBitmapInfo.byteOrder32Little.rawValue
        let alphaInfo = hasAlpha == true ? CGImageAlphaInfo.first.rawValue : CGImageAlphaInfo.noneSkipFirst.rawValue
        return CGImage(width: width , height: height, bitsPerComponent: bitComponent, bitsPerPixel: pixelDepth, bytesPerRow: width * (pixelDepth/8), space: CGColorSpace(name: CGColorSpace.sRGB)! , bitmapInfo: CGBitmapInfo(rawValue: (orderInfo | alphaInfo)), provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)
    }
}
