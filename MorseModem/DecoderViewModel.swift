//
//  DecoderViewModel.swift
//  MorseModem
//

import SwiftUI
import SwiftData

@MainActor
@Observable
class DecoderViewModel {
    var decodedText: String = ""
    var decodedMorse: String = ""
    var isImporting = false
    var importError: String?
    var showPermissionAlert = false
    var recordingDuration: TimeInterval = 0

    let morseDecoder = MorseDecoder()

    var isRecording: Bool { morseDecoder.isRecording }
    var waveformData: [Float] { morseDecoder.waveformData }

    private var modelContext: ModelContext
    private var durationTimer: Timer?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// Start recording
    func startRecording() async {
        do {
            try await morseDecoder.startRecording()

            recordingDuration = 0
            let startTime = Date()
            durationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.recordingDuration = Date().timeIntervalSince(startTime)
                }
            }
        } catch {
            importError = error.localizedDescription
            showPermissionAlert = true
        }
    }

    /// Stop recording
    func stopRecording() {
        morseDecoder.stopRecording()

        durationTimer?.invalidate()
        durationTimer = nil
        recordingDuration = 0

        decodedText = morseDecoder.decodedText
        decodedMorse = morseDecoder.decodedMorse

        saveMessage()
    }

    /// Import audio file
    func importAudioFile(url: URL) async {
        isImporting = true
        importError = nil

        var workingURL = url
        var needsCleanup = false
        var didStartAccessing = false

        defer {
            if didStartAccessing {
                url.stopAccessingSecurityScopedResource()
            }
            if needsCleanup {
                try? FileManager.default.removeItem(at: workingURL)
            }
        }

        do {
            // Files in Inbox may be cleaned up — copy to temp location
            if url.path.contains("/Inbox/") {
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(url.lastPathComponent)
                try? FileManager.default.removeItem(at: tempURL)
                try FileManager.default.copyItem(at: url, to: tempURL)
                workingURL = tempURL
                needsCleanup = true
            }

            // Access security-scoped resource for files outside Inbox
            if !url.path.contains("/Inbox/") && url.isFileURL {
                didStartAccessing = url.startAccessingSecurityScopedResource()
            }

            try await morseDecoder.decodeFromFile(url: workingURL)

            decodedText = morseDecoder.decodedText
            decodedMorse = morseDecoder.decodedMorse

            if !decodedText.isEmpty {
                saveMessage()
            }

            isImporting = false
        } catch {
            importError = String(localized: "Failed to import audio file: \(error.localizedDescription)")
            isImporting = false
        }
    }

    /// Copy decoded text to clipboard
    func copyToClipboard() {
        ClipboardHelper.copy(decodedText)
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
