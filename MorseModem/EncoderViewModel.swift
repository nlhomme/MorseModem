//
//  EncoderViewModel.swift
//  MorseModem
//
//  Created by Nicolas Lhomme on 26/01/2026.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

@MainActor
@Observable
class EncoderViewModel {
    var inputText: String = ""
    var morseCode: String = ""
    var isExporting = false
    var exportError: String?
    
    let toneGenerator = ToneGenerator()
    
    private var modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    /// Update Morse code when text changes
    func updateMorseCode() {
        morseCode = MorseCodeMap.encode(inputText)
    }
    
    /// Play Morse code
    func playMorse(settings: AppSettings) async {
        guard !morseCode.isEmpty else { return }
        
        await toneGenerator.playMorse(morseCode, settings: settings)
        
        // Save to history
        saveMessage()
    }
    
    /// Stop playing
    func stopPlaying() {
        toneGenerator.stop()
    }
    
    /// Export audio file
    func exportAudio(settings: AppSettings) async -> URL? {
        guard !morseCode.isEmpty else { return nil }
        
        isExporting = true
        exportError = nil
        
        let fileName = "morse_\(Date().timeIntervalSince1970).m4a"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try await toneGenerator.exportMorseAudio(morse: morseCode, settings: settings, to: tempURL)
            isExporting = false
            
            // Save to history
            saveMessage()
            
            return tempURL
        } catch {
            exportError = error.localizedDescription
            isExporting = false
            return nil
        }
    }
    
    /// Save message to history
    private func saveMessage() {
        guard !inputText.isEmpty else { return }
        
        let message = Message(text: inputText, morseCode: morseCode, isEncoded: true)
        modelContext.insert(message)
        
        try? modelContext.save()
    }
    
    /// Clear input
    func clear() {
        inputText = ""
        morseCode = ""
    }
}
