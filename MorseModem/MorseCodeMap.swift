//
//  MorseCodeMap.swift
//  MorseModem
//
//  Created by Nicolas Lhomme on 26/01/2026.
//

import Foundation

private nonisolated(unsafe) let _charToMorse: [Character: String] = [
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

private nonisolated(unsafe) let _morseToChar: [String: Character] = {
    var dict: [String: Character] = [:]
    for (char, morse) in _charToMorse where morse != " " {
        dict[morse] = char
    }
    return dict
}()

struct MorseCodeMap {
    /// Character to Morse code mapping
    nonisolated static var charToMorse: [Character: String] { _charToMorse }

    /// Reverse mapping: Morse code to character
    nonisolated static var morseToChar: [String: Character] { _morseToChar }

    /// Encode text to Morse code
    nonisolated static func encode(_ text: String) -> String {
        // Split on spaces first so words are joined with double-space, not triple
        let words = text.uppercased().components(separatedBy: " ").filter { !$0.isEmpty }
        return words
            .map { word in word.compactMap { _charToMorse[$0] }.joined(separator: " ") }
            .joined(separator: "  ")
    }

    /// Decode Morse code to text
    nonisolated static func decode(_ morse: String) -> String {
        let words = morse.components(separatedBy: "  ") // Double space for word separation
        return words.map { word in
            word.components(separatedBy: " ")
                .compactMap { _morseToChar[$0] }
                .map { String($0) }
                .joined()
        }.joined(separator: " ")
    }

    /// Get all supported characters grouped by category.
    /// Category names are raw localization keys; callers should localize them with LocalizedStringKey.
    nonisolated static func allCharacters() -> [(category: String, characters: [(char: Character, morse: String)])] {
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let numbers = "0123456789"
        let punctuation = ".,?'!/()&:;=+-_\"$@"

        return [
            ("Letters", letters.map { ($0, _charToMorse[$0] ?? "") }),
            ("Numbers", numbers.map { ($0, _charToMorse[$0] ?? "") }),
            ("Punctuation", punctuation.map { ($0, _charToMorse[$0] ?? "") })
        ]
    }
}
