//
//  Item.swift
//  SafeDriverNote
//
//  Created by mac on 2025/8/18.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
