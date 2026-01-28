//
//  MorseDecoder.swift
//  MorseModem
//

import AVFoundation
import Accelerate

@MainActor
@Observable
class MorseDecoder {
    var isRecording = false
    var decodedMorse = ""
    var decodedText = ""
    var waveformData: [Float] = []

    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var recordedSamples: [Float] = []
    private let sampleRate: Double = 44100.0

    // Named constants
    private let bufferSize: AVAudioFrameCount = 4096
    private let envelopeWindowSize = 512
    private let maxWaveformSamples = 1000
    private let noiseGateThreshold: Float = 0.05

    // Detection parameters
    private var detectedUnitDuration: Double = 0.1

    /// Request microphone permission
    func requestMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    private func configureAudioSessionForRecording() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement)
            try audioSession.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }

    /// Start recording and real-time decoding
    func startRecording() async throws {
        guard !isRecording else { return }

        let granted = await requestMicrophonePermission()
        guard granted else {
            throw NSError(domain: "MorseDecoder", code: -1, userInfo: [NSLocalizedDescriptionKey: "Microphone permission denied"])
        }

        recordedSamples.removeAll()
        decodedMorse = ""
        decodedText = ""
        waveformData.removeAll()
        waveformData.reserveCapacity(maxWaveformSamples)

        configureAudioSessionForRecording()

        let engine = AVAudioEngine()
        audioEngine = engine
        inputNode = engine.inputNode

        let inputFormat = engine.inputNode.inputFormat(forBus: 0)

        engine.inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: inputFormat) { [weak self] buffer, _ in
            Task { @MainActor in
                self?.processAudioBuffer(buffer)
            }
        }

        try engine.start()
        isRecording = true
    }

    /// Stop recording and decode
    func stopRecording() {
        guard isRecording else { return }

        inputNode?.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        inputNode = nil
        isRecording = false

        decodeMorseFromSamples()
    }

    /// Process audio buffer in real-time
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }

        let frameLength = Int(buffer.frameLength)
        let samples = Array(UnsafeBufferPointer(start: channelData, count: frameLength))

        recordedSamples.append(contentsOf: samples)

        // Compute RMS once
        let rms = sqrt(samples.reduce(0) { $0 + $1 * $1 } / Float(samples.count))

        if waveformData.count < maxWaveformSamples {
            waveformData.append(rms)
        } else {
            // Shift left and append — use replaceSubrange for efficiency
            waveformData.replaceSubrange(0..<1, with: EmptyCollection())
            waveformData.append(rms)
        }
    }

    /// Decode Morse code from recorded samples
    private func decodeMorseFromSamples() {
        guard !recordedSamples.isEmpty else { return }

        let envelope = computeEnvelope(samples: recordedSamples)
        let segments = detectSegments(envelope: envelope)
        detectUnitDuration(segments: segments)
        let morse = segmentsToMorse(segments: segments)
        decodedMorse = morse
        decodedText = MorseCodeMap.decode(morse)
    }

    /// Compute amplitude envelope
    private func computeEnvelope(samples: [Float]) -> [Float] {
        let halfWindow = envelopeWindowSize / 2
        var envelope: [Float] = []
        envelope.reserveCapacity(samples.count / halfWindow + 1)

        for i in stride(from: 0, to: samples.count, by: halfWindow) {
            let end = min(i + envelopeWindowSize, samples.count)
            let window = samples[i..<end]

            let rms = sqrt(window.reduce(0) { $0 + $1 * $1 } / Float(window.count))
            envelope.append(rms)
        }

        return envelope
    }

    /// Detect tone and silence segments
    private func detectSegments(envelope: [Float]) -> [(isTone: Bool, duration: Double)] {
        guard !envelope.isEmpty else { return [] }

        var segments: [(Bool, Double)] = []

        let sortedEnvelope = envelope.sorted()
        let threshold = sortedEnvelope[sortedEnvelope.count * 3 / 4] * 0.5

        let frameDuration = Double(envelopeWindowSize) / 2.0 / sampleRate

        var currentState = envelope[0] > threshold
        var currentDuration = 0

        for value in envelope {
            let isTone = value > threshold

            if isTone == currentState {
                currentDuration += 1
            } else {
                if currentDuration > 0 {
                    segments.append((currentState, Double(currentDuration) * frameDuration))
                }
                currentState = isTone
                currentDuration = 1
            }
        }

        if currentDuration > 0 {
            segments.append((currentState, Double(currentDuration) * frameDuration))
        }

        return segments
    }

    /// Auto-detect unit duration (dot duration)
    private func detectUnitDuration(segments: [(isTone: Bool, duration: Double)]) {
        let toneDurations = segments.filter { $0.isTone }.map { $0.duration }
        guard !toneDurations.isEmpty else { return }

        let minDuration = toneDurations.min() ?? 0.1
        detectedUnitDuration = minDuration
    }

    /// Convert segments to Morse code string
    private func segmentsToMorse(segments: [(isTone: Bool, duration: Double)]) -> String {
        var morse = ""
        let unit = detectedUnitDuration

        for segment in segments {
            if segment.isTone {
                let units = segment.duration / unit
                morse += units < 2 ? "." : "-"
            } else {
                let units = segment.duration / unit
                if units < 2 {
                    // Intra-character gap (ignore)
                } else if units < 5 {
                    morse += " "
                } else {
                    morse += "  "
                }
            }
        }

        return morse
    }

    /// Decode from audio file
    func decodeFromFile(url: URL) async throws {
        let audioFile = try AVAudioFile(forReading: url)

        guard let buffer = AVAudioPCMBuffer(
            pcmFormat: audioFile.processingFormat,
            frameCapacity: AVAudioFrameCount(audioFile.length)
        ) else {
            throw NSError(domain: "MorseDecoder", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to create buffer"])
        }

        try audioFile.read(into: buffer)

        guard let channelData = buffer.floatChannelData?[0] else {
            throw NSError(domain: "MorseDecoder", code: -3, userInfo: [NSLocalizedDescriptionKey: "Failed to read audio data"])
        }

        recordedSamples = Array(UnsafeBufferPointer(start: channelData, count: Int(buffer.frameLength)))
        decodeMorseFromSamples()
    }
}
