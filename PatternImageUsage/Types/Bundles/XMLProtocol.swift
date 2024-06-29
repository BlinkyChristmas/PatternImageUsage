// Copyright © 2024 Charles Kerr. All rights reserved.

import Foundation

protocol XMLProtocol {
    var xml:XMLElement { get }
    init(element:XMLElement) throws
}
