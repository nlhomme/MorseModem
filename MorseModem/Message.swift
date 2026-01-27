//
//  Message.swift
//  MorseModem
//
//  Created by Nicolas Lhomme on 26/01/2026.
//

import Foundation
import SwiftData

@Model
final class Message {
    var text: String
    var morseCode: String
    var timestamp: Date
    var isEncoded: Bool // true for encoded, false for decoded
    
    init(text: String, morseCode: String, timestamp: Date = Date(), isEncoded: Bool) {
        self.text = text
        self.morseCode = morseCode
        self.timestamp = timestamp
        self.isEncoded = isEncoded
    }
}
