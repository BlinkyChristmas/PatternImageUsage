// Copyright © 2024 Charles Kerr. All rights reserved.

import Foundation

class PatternCache : NSObject {
    
    var patterns = [String:[[TransitionType]]]()
    func reset() {
        patterns.removeAll()
    }
    func patternFor(base:URL,key:String) throws -> [[TransitionType]] {
        if patterns.keys.contains(key) {
            return patterns[key]!
        }
        else {
            do {
                let temp = try loadPattern(url: base.appending(path: key))
                patterns[key] = temp
                return temp
           }
            catch {
                throw GeneralError(errorMessage: "Failure looking for \(base.appending(path: key).path() )", failure: error.localizedDescription)
            }
        }
    }
    
}
