//
//  AppSettings.swift
//  MorseModem
//
//  Created by Nicolas Lhomme on 26/01/2026.
//

import Foundation
import SwiftData

@Model
final class AppSettings {
    var toneFrequency: Double // Hz
    var wordsPerMinute: Int // WPM
    var volume: Double // 0.0 to 1.0
    
    init(toneFrequency: Double = 700, wordsPerMinute: Int = 12, volume: Double = 0.8) {
        self.toneFrequency = toneFrequency
        self.wordsPerMinute = wordsPerMinute
        self.volume = volume
    }
    
    /// Duration of a dot in seconds based on WPM
    var dotDuration: Double {
        // Standard: PARIS is the word used for WPM calculation (50 units)
        // 1 WPM = 50 units per minute
        return 60.0 / (50.0 * Double(wordsPerMinute))
    }
    
    var dashDuration: Double {
        return dotDuration * 3
    }
    
    var intraCharacterGap: Double {
        return dotDuration
    }
    
    var interCharacterGap: Double {
        return dotDuration * 3
    }
    
    var wordGap: Double {
        return dotDuration * 7
    }

    /// Resolve settings from a query result, creating defaults if needed
    static func resolve(from array: [AppSettings], in context: ModelContext) -> AppSettings {
        if let existing = array.first {
            return existing
        }
        let newSettings = AppSettings()
        context.insert(newSettings)
        try? context.save()
        return newSettings
    }
}
