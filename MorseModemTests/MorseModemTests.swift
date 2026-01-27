//
//  MorseModemTests.swift
//  MorseModemTests
//
//  Created by Nicolas Lhomme on 26/01/2026.
//

import Testing
@testable import MorseModem

@Suite("Morse Code Encoding Tests")
struct MorseEncodingTests {
    
    @Test("Encoding letters A-Z")
    func encodeLetters() async throws {
        let input = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let expected = ".- -... -.-. -.. . ..-. --. .... .. .--- -.- .-.. -- -. --- .--. --.- .-. ... - ..- ...- .-- -..- -.-- --.."
        
        let result = MorseCodeMap.encode(input)
        #expect(result == expected, "Letters should be encoded correctly")
    }
    
    @Test("Encoding numbers 0-9")
    func encodeNumbers() async throws {
        let input = "0123456789"
        let expected = "----- .---- ..--- ...-- ....- ..... -.... --... ---.. ----."
        
        let result = MorseCodeMap.encode(input)
        #expect(result == expected, "Numbers should be encoded correctly")
    }
    
    @Test("Encoding SOS")
    func encodeSOSDistressSignal() async throws {
        let input = "SOS"
        let expected = "... --- ..."
        
        let result = MorseCodeMap.encode(input)
        #expect(result == expected, "SOS should be encoded correctly")
    }
    
    @Test("Encoding with spaces")
    func encodeWithSpaces() async throws {
        let input = "HELLO WORLD"
        let expected = ".... . .-.. .-.. ---  .-- --- .-. .-.. -.."
        
        let result = MorseCodeMap.encode(input)
        #expect(result == expected, "Words with spaces should be encoded correctly")
    }
    
    @Test("Encoding lowercase converts to uppercase")
    func encodeLowercase() async throws {
        let input = "hello"
        let expected = ".... . .-.. .-.. ---"
        
        let result = MorseCodeMap.encode(input)
        #expect(result == expected, "Lowercase should be converted to uppercase")
    }
    
    @Test("Encoding punctuation")
    func encodePunctuation() async throws {
        let input = ".,?"
        let expected = ".-.-.- --..-- ..--.."
        
        let result = MorseCodeMap.encode(input)
        #expect(result == expected, "Punctuation should be encoded correctly")
    }
}

@Suite("Morse Code Decoding Tests")
struct MorseDecodingTests {
    
    @Test("Decoding SOS")
    func decodeSOSDistressSignal() async throws {
        let input = "... --- ..."
        let expected = "SOS"
        
        let result = MorseCodeMap.decode(input)
        #expect(result == expected, "SOS should be decoded correctly")
    }
    
    @Test("Decoding with word separation")
    func decodeWithWords() async throws {
        let input = ".... . .-.. .-.. ---  .-- --- .-. .-.. -.."
        let expected = "HELLO WORLD"
        
        let result = MorseCodeMap.decode(input)
        #expect(result == expected, "Words should be decoded correctly with spaces")
    }
    
    @Test("Decoding numbers")
    func decodeNumbers() async throws {
        let input = ".---- ..--- ...--"
        let expected = "123"
        
        let result = MorseCodeMap.decode(input)
        #expect(result == expected, "Numbers should be decoded correctly")
    }
    
    @Test("Round-trip encoding and decoding")
    func roundTripEncodeDecode() async throws {
        let original = "THE QUICK BROWN FOX"
        
        let encoded = MorseCodeMap.encode(original)
        let decoded = MorseCodeMap.decode(encoded)
        
        #expect(decoded == original, "Round-trip encoding/decoding should preserve text")
    }
}

@Suite("App Settings Tests")
struct AppSettingsTests {
    
    @Test("Default settings")
    func defaultSettings() async throws {
        let settings = AppSettings()
        
        #expect(settings.toneFrequency == 700, "Default frequency should be 700 Hz")
        #expect(settings.wordsPerMinute == 12, "Default WPM should be 12")
        #expect(settings.volume == 0.8, "Default volume should be 0.8")
    }
    
    @Test("Timing calculations at 12 WPM")
    func timingCalculations() async throws {
        let settings = AppSettings(wordsPerMinute: 12)
        
        let expectedDotDuration = 60.0 / (50.0 * 12.0) // 0.1 seconds
        
        #expect(abs(settings.dotDuration - expectedDotDuration) < 0.001, "Dot duration should be calculated correctly")
        #expect(abs(settings.dashDuration - expectedDotDuration * 3) < 0.001, "Dash duration should be 3x dot duration")
        #expect(abs(settings.interCharacterGap - expectedDotDuration * 3) < 0.001, "Inter-character gap should be 3x dot duration")
        #expect(abs(settings.wordGap - expectedDotDuration * 7) < 0.001, "Word gap should be 7x dot duration")
    }
    
    @Test("Timing at different speeds")
    func timingAtDifferentSpeeds() async throws {
        let slow = AppSettings(wordsPerMinute: 5)
        let fast = AppSettings(wordsPerMinute: 40)
        
        #expect(slow.dotDuration > fast.dotDuration, "Slower speed should have longer dot duration")
        #expect(slow.wordGap > fast.wordGap, "Slower speed should have longer word gap")
    }
}
@Suite("Morse Code Map Tests")
struct MorseCodeMapTests {
    
    @Test("All characters have mappings")
    func allCharactersHaveMappings() async throws {
        let allChars = MorseCodeMap.allCharacters()
        
        var totalCount = 0
        for category in allChars {
            totalCount += category.characters.count
        }
        
        #expect(totalCount > 0, "Should have character mappings")
        #expect(allChars.count == 3, "Should have 3 categories: Letters, Numbers, Punctuation")
    }
    
    @Test("Reverse mapping consistency")
    func reverseMappingConsistency() async throws {
        // Verify that encoding and then using reverse map works
        for (char, morse) in MorseCodeMap.charToMorse {
            if char != " " {
                #expect(MorseCodeMap.morseToChar[morse] == char, "Reverse mapping should be consistent for \(char)")
            }
        }
    }
}


