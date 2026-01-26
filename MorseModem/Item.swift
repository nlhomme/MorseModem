//
//  Item.swift
//  MorseModem
//
//  Created by Nicolas Lhomme on 26/01/2026.
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
