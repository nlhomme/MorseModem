//
//  DecoderViewModel.swift
//  MorseModem
//
//  Created by Nicolas Lhomme on 26/01/2026.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers
internal import Combine

@MainActor
@Observable
class DecoderViewModel {
    var decodedText: String = ""
    var decodedMorse: String = ""
    var isImporting = false
    var importError: String?
    var showPermissionAlert = false
    var recordingDuration: TimeInterval = 0
    var isRecording: Bool = false
    var waveformData: [Float] = []
    
    let morseDecoder = MorseDecoder()
    
    private var modelContext: ModelContext
    private var recordingStartTime: Date?
    private var durationTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        
        // Observe decoder changes
        observeDecoder()
    }
    
    /// Observe decoder changes
    private func observeDecoder() {
        // Bridge Combine's @Published to @Observable
        morseDecoder.$isRecording
            .sink { [weak self] isRecording in
                self?.isRecording = isRecording
            }
            .store(in: &cancellables)
        
        morseDecoder.$waveformData
            .sink { [weak self] waveformData in
                self?.waveformData = waveformData
            }
            .store(in: &cancellables)
    }
    
    /// Start recording
    func startRecording() async {
        print("🎤 DecoderViewModel: startRecording called")
        do {
            try await morseDecoder.startRecording()
            print("🎤 DecoderViewModel: Recording started, isRecording = \(morseDecoder.isRecording)")
            
            // Start the duration timer
            recordingStartTime = Date()
            recordingDuration = 0
            let startTime = Date()
            durationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.recordingDuration = Date().timeIntervalSince(startTime)
                }
            }
        } catch {
            print("🎤 DecoderViewModel: Recording failed - \(error.localizedDescription)")
            importError = error.localizedDescription
            showPermissionAlert = true
        }
    }
    
    /// Stop recording
    func stopRecording() {
        print("🎤 DecoderViewModel: stopRecording called")
        morseDecoder.stopRecording()
        print("🎤 DecoderViewModel: Recording stopped, isRecording = \(morseDecoder.isRecording)")
        
        // Stop the duration timer
        durationTimer?.invalidate()
        durationTimer = nil
        recordingStartTime = nil
        recordingDuration = 0
        
        decodedText = morseDecoder.decodedText
        decodedMorse = morseDecoder.decodedMorse
        
        print("🎤 DecoderViewModel: decodedText = '\(decodedText)'")
        print("🎤 DecoderViewModel: decodedMorse = '\(decodedMorse)'")
        
        // Save to history
        saveMessage()
    }
    
    /// Import audio file
    func importAudioFile(url: URL) async {
        print("🎵 ===== IMPORT AUDIO FILE =====")
        print("🎵 URL: \(url)")
        print("🎵 URL.path: \(url.path)")
        print("🎵 URL.absoluteString: \(url.absoluteString)")
        print("🎵 URL.isFileURL: \(url.isFileURL)")
        print("🎵 URL.scheme: \(url.scheme ?? "nil")")
        
        let fileExists = FileManager.default.fileExists(atPath: url.path)
        print("🎵 File exists at path: \(fileExists)")
        
        if !fileExists {
            // Try with path(percentEncoded: false)
            if #available(iOS 16.0, *) {
                let altPath = url.path(percentEncoded: false)
                let altExists = FileManager.default.fileExists(atPath: altPath)
                print("🎵 Alternate path: \(altPath)")
                print("🎵 File exists at alternate path: \(altExists)")
            }
        }
        
        isImporting = true
        importError = nil
        
        var workingURL = url
        var needsCleanup = false
        var didStartAccessing = false
        
        do {
            // Check if we can read the file attributes
            if fileExists {
                let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
                print("🎵 File attributes: \(attributes ?? [:])")
                print("🎵 File size: \(attributes?[.size] ?? "unknown")")
            }
            
            // For shared files, we might need to copy them to a temporary location
            // because they might be in the Inbox and get cleaned up
            if url.path.contains("/Inbox/") || url.path.contains("Inbox") {
                print("📁 File is in Inbox, creating working copy...")
                let tempDir = FileManager.default.temporaryDirectory
                let tempURL = tempDir.appendingPathComponent(url.lastPathComponent)
                
                // Remove existing temp file if present
                try? FileManager.default.removeItem(at: tempURL)
                
                // Copy the file
                try FileManager.default.copyItem(at: url, to: tempURL)
                workingURL = tempURL
                needsCleanup = true
                print("✅ Created working copy at: \(tempURL.path)")
            }
            
            // Try to access with security-scoped resource if needed
            // Only for files NOT in Inbox and that are file URLs
            if !url.path.contains("/Inbox/") && !url.path.contains("Inbox") && url.isFileURL {
                print("🔑 Attempting security-scoped access...")
                didStartAccessing = url.startAccessingSecurityScopedResource()
                print("🔑 Security-scoped access result: \(didStartAccessing)")
            } else {
                print("ℹ️ Skipping security-scoped access (not needed)")
            }
            
            print("🎵 Decoding file from: \(workingURL.path)")
            try await morseDecoder.decodeFromFile(url: workingURL)
            
            decodedText = morseDecoder.decodedText
            decodedMorse = morseDecoder.decodedMorse
            
            print("✅ Decoded text: '\(decodedText)'")
            print("✅ Decoded morse: '\(decodedMorse)'")
            
            // Save to history only if we got results
            if !decodedText.isEmpty {
                saveMessage()
                print("✅ Saved to history")
            } else {
                print("⚠️ No text decoded, not saving to history")
            }
            
            isImporting = false
            print("✅ Import completed successfully")
            print("🎵 ===========================")
            
        } catch {
            print("❌ Import error: \(error.localizedDescription)")
            print("❌ Error type: \(type(of: error))")
            print("❌ Full error: \(error)")
            importError = String(localized: "Failed to import audio file: \(error.localizedDescription)")
            isImporting = false
            print("🎵 ===========================")
        }
        
        // Cleanup
        if didStartAccessing {
            url.stopAccessingSecurityScopedResource()
            print("🔒 Released security-scoped resource")
        }
        
        if needsCleanup {
            try? FileManager.default.removeItem(at: workingURL)
            print("🗑️ Cleaned up temporary file")
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
