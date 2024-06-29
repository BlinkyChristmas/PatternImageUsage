// Copyright © 2024 Charles Kerr. All rights reserved.

import Foundation
import UniformTypeIdentifiers
func contentsOf(url:URL?,with pathExtension:String? = nil,includeExtension:Bool = true) throws -> [String] {
    var contents = [String]()
    guard let url = url else { return contents }
    do{
        let temp = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: [.isRegularFileKey,.isDirectoryKey,.isHiddenKey,.isReadableKey])
        for entry in temp {
            if !entry.isHidden && entry.isReqularFile && entry.isReadable {
                if pathExtension == nil || pathExtension == entry.pathExtension  {
                    contents.append( (includeExtension ? entry.lastPathComponent : entry.deletingPathExtension().lastPathComponent))
                }
            }
        }
        return contents
    }
    catch {
        throw GeneralError(errorMessage: "Unable gather contents of \(url.path())", failure: "\(error.localizedDescription)")
    }
}

func randomAlphanumericString(_ length: Int) -> String {
   let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
   let len = UInt32(letters.count)
   var random = SystemRandomNumberGenerator()
   var randomString = ""
   for _ in 0..<length {
      let randomIndex = Int(random.next(upperBound: len))
      let randomCharacter = letters[letters.index(letters.startIndex, offsetBy: randomIndex)]
      randomString.append(randomCharacter)
   }
   return randomString
}

