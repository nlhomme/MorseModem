//
//  MorseCodeMap.swift
//  MorseModem
//
//  Created by Nicolas Lhomme on 26/01/2026.
//

import Foundation

struct MorseCodeMap {
    /// Character to Morse code mapping
    static let charToMorse: [Character: String] = [
        "A": ".-", "B": "-...", "C": "-.-.", "D": "-..", "E": ".", "F": "..-.",
        "G": "--.", "H": "....", "I": "..", "J": ".---", "K": "-.-", "L": ".-..",
        "M": "--", "N": "-.", "O": "---", "P": ".--.", "Q": "--.-", "R": ".-.",
        "S": "...", "T": "-", "U": "..-", "V": "...-", "W": ".--", "X": "-..-",
        "Y": "-.--", "Z": "--..",
        "0": "-----", "1": ".----", "2": "..---", "3": "...--", "4": "....-",
        "5": ".....", "6": "-....", "7": "--...", "8": "---..", "9": "----.",
        ".": ".-.-.-", ",": "--..--", "?": "..--..", "'": ".----.", "!": "-.-.--",
        "/": "-..-.", "(": "-.--.", ")": "-.--.-", "&": ".-...", ":": "---...",
        ";": "-.-.-.", "=": "-...-", "+": ".-.-.", "-": "-....-", "_": "..--.-",
        "\"": ".-..-.", "$": "...-..-", "@": ".--.-.", " ": " "
    ]
    
    /// Reverse mapping: Morse code to character
    static let morseToChar: [String: Character] = {
        var dict: [String: Character] = [:]
        for (char, morse) in charToMorse {
            if morse != " " {
                dict[morse] = char
            }
        }
        return dict
    }()
    
    /// Encode text to Morse code
    static func encode(_ text: String) -> String {
        return text.uppercased().compactMap { char in
            charToMorse[char]
        }.joined(separator: " ")
    }
    
    /// Decode Morse code to text
    static func decode(_ morse: String) -> String {
        let words = morse.components(separatedBy: "  ") // Double space for word separation
        
        return words.map { word in
            let characters = word.components(separatedBy: " ")
            return characters.compactMap { pattern in
                morseToChar[pattern]
            }.map { String($0) }.joined()
        }.joined(separator: " ")
    }
    
    /// Get all supported characters grouped by category
    static func allCharacters() -> [(category: String, characters: [(char: Character, morse: String)])] {
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let numbers = "0123456789"
        let punctuation = ".,?'!/()&:;=+-_\"$@"
        
        return [
            (String(localized: "Letters"), letters.map { ($0, charToMorse[$0] ?? "") }),
            (String(localized: "Numbers"), numbers.map { ($0, charToMorse[$0] ?? "") }),
            (String(localized: "Punctuation"), punctuation.map { ($0, charToMorse[$0] ?? "") })
        ]
    }
}
