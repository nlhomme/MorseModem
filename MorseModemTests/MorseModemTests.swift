//
//  MorseModemTests.swift
//  MorseModemTests
//
//  Created by Nicolas Lhomme on 26/01/2026.
//

import Testing
import AVFoundation
import SwiftData
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

// MARK: - ToneGenerator Tests

@MainActor
@Suite("Tone Generator Tests")
struct ToneGeneratorTests {

    @Test("generateMorseAudio returns a buffer for valid morse")
    func returnsBufferForValidMorse() async throws {
        let buffer = ToneGenerator().generateMorseAudio(morse: ".", settings: AppSettings())
        #expect(buffer != nil)
    }

    @Test("Single dot buffer duration matches dot duration")
    func singleDotDuration() async throws {
        let settings = AppSettings(wordsPerMinute: 12)
        let buffer = try #require(ToneGenerator().generateMorseAudio(morse: ".", settings: settings))
        let actual = Double(buffer.frameLength) / 44100.0
        #expect(abs(actual - settings.dotDuration) < 0.001)
    }

    @Test("S (…) buffer duration equals 3 dots + 2 intra-char gaps")
    func sLetterDuration() async throws {
        let settings = AppSettings(wordsPerMinute: 12)
        let buffer = try #require(ToneGenerator().generateMorseAudio(morse: "...", settings: settings))
        let expected = 3 * settings.dotDuration + 2 * settings.intraCharacterGap
        let actual = Double(buffer.frameLength) / 44100.0
        #expect(abs(actual - expected) < 0.002)
    }

    @Test("Dash buffer duration is three times dot duration")
    func dashDuration() async throws {
        let settings = AppSettings(wordsPerMinute: 12)
        let dot = try #require(ToneGenerator().generateMorseAudio(morse: ".", settings: settings))
        let dash = try #require(ToneGenerator().generateMorseAudio(morse: "-", settings: settings))
        let dotSecs = Double(dot.frameLength) / 44100.0
        let dashSecs = Double(dash.frameLength) / 44100.0
        #expect(abs(dashSecs - dotSecs * 3) < 0.002)
    }
}

// MARK: - EncoderViewModel Tests

@MainActor
@Suite("Encoder View Model Tests")
struct EncoderViewModelTests {

    private func makeViewModel() throws -> EncoderViewModel {
        let container = try ModelContainer(
            for: Message.self, AppSettings.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return EncoderViewModel(modelContext: container.mainContext)
    }

    @Test("updateMorseCode encodes inputText to morse")
    func updateMorseCode() async throws {
        let vm = try makeViewModel()
        vm.inputText = "SOS"
        vm.updateMorseCode()
        #expect(vm.morseCode == "... --- ...")
    }

    @Test("updateMorseCode produces empty output for empty input")
    func emptyInputGivesEmptyMorse() async throws {
        let vm = try makeViewModel()
        vm.inputText = ""
        vm.updateMorseCode()
        #expect(vm.morseCode.isEmpty)
    }

    @Test("clear resets inputText and morseCode")
    func clearResetsState() async throws {
        let vm = try makeViewModel()
        vm.inputText = "HELLO"
        vm.morseCode = ".... . .-.. .-.. ---"
        vm.clear()
        #expect(vm.inputText.isEmpty)
        #expect(vm.morseCode.isEmpty)
    }
}

// MARK: - AppSettings Resolve Tests

@MainActor
@Suite("App Settings Resolve Tests")
struct AppSettingsResolveTests {

    @Test("Creates default settings when array is empty")
    func createsDefaultsWhenEmpty() async throws {
        let container = try ModelContainer(
            for: AppSettings.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let settings = AppSettings.resolve(from: [], in: container.mainContext)
        #expect(settings.toneFrequency == 700)
        #expect(settings.wordsPerMinute == 12)
        #expect(settings.volume == 0.8)
    }

    @Test("Returns first element when array is non-empty")
    func returnsExistingWhenPresent() async throws {
        let container = try ModelContainer(
            for: AppSettings.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let custom = AppSettings(toneFrequency: 500, wordsPerMinute: 20, volume: 0.5)
        container.mainContext.insert(custom)
        let resolved = AppSettings.resolve(from: [custom], in: container.mainContext)
        #expect(resolved.toneFrequency == 500)
        #expect(resolved.wordsPerMinute == 20)
        #expect(resolved.volume == 0.5)
    }
}

// MARK: - MorseDecoder Signal Tests

@MainActor
@Suite("Morse Decoder Signal Tests")
struct MorseDecoderSignalTests {

    @Test("computeEnvelope returns 1.0 for full-amplitude signal")
    func envelopeFullAmplitude() async throws {
        let envelope = MorseDecoder().computeEnvelope(samples: [Float](repeating: 1.0, count: 1024))
        #expect(!envelope.isEmpty)
        #expect(envelope.allSatisfy { abs($0 - 1.0) < 0.001 })
    }

    @Test("computeEnvelope returns 0.0 for silence")
    func envelopeSilence() async throws {
        let envelope = MorseDecoder().computeEnvelope(samples: [Float](repeating: 0.0, count: 1024))
        #expect(envelope.allSatisfy { $0 == 0.0 })
    }

    @Test("detectSegments groups consecutive tones and silences")
    func detectsTonesAndSilences() async throws {
        // [1, 1, 1, 0, 0]: sorted 75th-pct = 1.0, threshold = 0.5 → tone×3, silence×2
        let segments = MorseDecoder().detectSegments(envelope: [1.0, 1.0, 1.0, 0.0, 0.0])
        #expect(segments.count == 2)
        #expect(segments[0].isTone == true)
        #expect(segments[1].isTone == false)
    }

    @Test("segmentsToMorse: 1-unit tone → dot")
    func shortToneIsDot() async throws {
        let decoder = MorseDecoder()
        let seg: [(isTone: Bool, duration: Double)] = [(true, 0.1)]
        decoder.detectUnitDuration(segments: seg)
        #expect(decoder.segmentsToMorse(segments: seg) == ".")
    }

    @Test("segmentsToMorse: 3-unit tone → dash")
    func longToneIsDash() async throws {
        let decoder = MorseDecoder()
        decoder.detectUnitDuration(segments: [(true, 0.1)])
        #expect(decoder.segmentsToMorse(segments: [(true, 0.3)]) == "-")
    }

    @Test("segmentsToMorse: dot + intra-gap + dash → .- (letter A)")
    func letterA() async throws {
        let decoder = MorseDecoder()
        let seg: [(isTone: Bool, duration: Double)] = [
            (true, 0.1), (false, 0.08), (true, 0.3)
        ]
        decoder.detectUnitDuration(segments: seg)
        #expect(decoder.segmentsToMorse(segments: seg) == ".-")
    }

    @Test("segmentsToMorse: 3-unit silence → inter-character space")
    func interCharacterSpace() async throws {
        let decoder = MorseDecoder()
        decoder.detectUnitDuration(segments: [(true, 0.1)])
        let seg: [(isTone: Bool, duration: Double)] = [
            (true, 0.1), (false, 0.3), (true, 0.1)
        ]
        #expect(decoder.segmentsToMorse(segments: seg) == ". .")
    }

    @Test("segmentsToMorse: 7-unit silence → word gap (double space)")
    func wordGap() async throws {
        let decoder = MorseDecoder()
        decoder.detectUnitDuration(segments: [(true, 0.1)])
        let seg: [(isTone: Bool, duration: Double)] = [
            (true, 0.1), (false, 0.7), (true, 0.1)
        ]
        #expect(decoder.segmentsToMorse(segments: seg) == ".  .")
    }
}
