// Copyright © 2024 Charles Kerr. All rights reserved.

import Foundation

struct GeneralError : LocalizedError {
    
    var errorMessage:String?
    var failure:String?
    init(errorMessage: String?  ,failure: String? = nil ) {
        self.errorMessage = errorMessage
        self.failure = failure
    }
    
    var errorDescription: String? {
        guard errorMessage != nil else {
            return "Unknown Error"
        }
        guard failureReason != nil else {
            return self.errorMessage
        }
        return self.errorMessage! + " : " + failureReason!
    }
    var failureReason: String? {
        return  self.failure
    }
}
