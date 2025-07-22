//
//  Item.swift
//  Unified Portfolio
//
//  Created by Jordan Pauzie on 7/21/25.
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
