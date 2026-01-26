//
//  DecoderViewModel.swift
//  MorseModem
//
//  Created by Nicolas Lhomme on 26/01/2026.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

@MainActor
@Observable
class DecoderViewModel {
    var decodedText: String = ""
    var decodedMorse: String = ""
    var isImporting = false
    var importError: String?
    var showPermissionAlert = false
    
    let morseDecoder = MorseDecoder()
    
    private var modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        
        // Observe decoder changes
        Task {
            await observeDecoder()
        }
    }
    
    /// Observe decoder changes
    private func observeDecoder() async {
        // Note: In a production app, you might use Combine or async streams
        // For simplicity, we'll access decoder properties directly in views
    }
    
    /// Start recording
    func startRecording() async {
        do {
            try await morseDecoder.startRecording()
        } catch {
            importError = error.localizedDescription
            showPermissionAlert = true
        }
    }
    
    /// Stop recording
    func stopRecording() {
        morseDecoder.stopRecording()
        
        decodedText = morseDecoder.decodedText
        decodedMorse = morseDecoder.decodedMorse
        
        // Save to history
        saveMessage()
    }
    
    /// Import audio file
    func importAudioFile(url: URL) async {
        isImporting = true
        importError = nil
        
        do {
            // Access security-scoped resource
            guard url.startAccessingSecurityScopedResource() else {
                throw NSError(domain: "DecoderViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to access file"])
            }
            
            defer {
                url.stopAccessingSecurityScopedResource()
            }
            
            try await morseDecoder.decodeFromFile(url: url)
            
            decodedText = morseDecoder.decodedText
            decodedMorse = morseDecoder.decodedMorse
            
            // Save to history
            saveMessage()
            
            isImporting = false
        } catch {
            importError = error.localizedDescription
            isImporting = false
        }
    }
    
    /// Copy decoded text to clipboard
    func copyToClipboard() {
        #if os(iOS)
        UIPasteboard.general.string = decodedText
        #elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(decodedText, forType: .string)
        #endif
    }
    
    /// Save message to history
    private func saveMessage() {
        guard !decodedText.isEmpty else { return }
        
        let message = Message(text: decodedText, morseCode: decodedMorse, isEncoded: false)
        modelContext.insert(message)
        
        try? modelContext.save()
    }
    
    /// Clear results
    func clear() {
        decodedText = ""
        decodedMorse = ""
    }
}
