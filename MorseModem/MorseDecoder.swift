//
//  MorseDecoder.swift
//  MorseModem
//
//  Created by Nicolas Lhomme on 26/01/2026.
//

import AVFoundation
import Accelerate
internal import Combine

@MainActor
class MorseDecoder: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var decodedMorse = ""
    @Published var decodedText = ""
    @Published var waveformData: [Float] = []
    
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var recordedSamples: [Float] = []
    private let sampleRate: Double = 44100.0
    
    // Detection parameters
    private var detectedUnitDuration: Double = 0.1 // Auto-detected
    private let noiseGateThreshold: Float = 0.05
    private let minToneFrequency: Float = 300.0
    private let maxToneFrequency: Float = 1500.0
    
    override init() {
        super.init()
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement)
            try audioSession.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    /// Request microphone permission
    func requestMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
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
        
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else { return }
        
        inputNode = audioEngine.inputNode
        let inputFormat = inputNode?.inputFormat(forBus: 0)
        
        inputNode?.installTap(onBus: 0, bufferSize: 4096, format: inputFormat) { [weak self] buffer, _ in
            Task { @MainActor in
                self?.processAudioBuffer(buffer)
            }
        }
        
        try audioEngine.start()
        isRecording = true
    }
    
    /// Stop recording and decode
    func stopRecording() {
        guard isRecording else { return }
        
        inputNode?.removeTap(onBus: 0)
        audioEngine?.stop()
        isRecording = false
        
        // Final decode
        decodeMorseFromSamples()
    }
    
    /// Process audio buffer in real-time
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        
        let frameLength = Int(buffer.frameLength)
        let samples = Array(UnsafeBufferPointer(start: channelData, count: frameLength))
        
        recordedSamples.append(contentsOf: samples)
        
        // Update waveform (downsample for display)
        if waveformData.count < 1000 { // Limit waveform data
            let rms = sqrt(samples.reduce(0) { $0 + $1 * $1 } / Float(samples.count))
            waveformData.append(rms)
        } else {
            waveformData.removeFirst()
            let rms = sqrt(samples.reduce(0) { $0 + $1 * $1 } / Float(samples.count))
            waveformData.append(rms)
        }
    }
    
    /// Decode Morse code from recorded samples
    private func decodeMorseFromSamples() {
        guard !recordedSamples.isEmpty else { return }
        
        // Step 1: Compute envelope (amplitude over time)
        let envelope = computeEnvelope(samples: recordedSamples)
        
        // Step 2: Detect tone/silence segments
        let segments = detectSegments(envelope: envelope)
        
        // Step 3: Auto-detect timing unit
        detectUnitDuration(segments: segments)
        
        // Step 4: Convert segments to Morse code
        let morse = segmentsToMorse(segments: segments)
        decodedMorse = morse
        
        // Step 5: Decode to text
        decodedText = MorseCodeMap.decode(morse)
    }
    
    /// Compute amplitude envelope
    private func computeEnvelope(samples: [Float]) -> [Float] {
        var envelope: [Float] = []
        let windowSize = 512
        
        for i in stride(from: 0, to: samples.count, by: windowSize / 2) {
            let end = min(i + windowSize, samples.count)
            let window = Array(samples[i..<end])
            
            // RMS amplitude
            let rms = sqrt(window.reduce(0) { $0 + $1 * $1 } / Float(window.count))
            envelope.append(rms)
        }
        
        return envelope
    }
    
    /// Detect tone and silence segments
    private func detectSegments(envelope: [Float]) -> [(isTone: Bool, duration: Double)] {
        var segments: [(Bool, Double)] = []
        
        // Auto-detect threshold
        let sortedEnvelope = envelope.sorted()
        let threshold = sortedEnvelope[sortedEnvelope.count * 3 / 4] * 0.5
        
        var currentState = envelope[0] > threshold
        var currentDuration = 0
        
        let frameDuration = 512.0 / 2.0 / sampleRate // Duration per envelope sample
        
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
        
        // Find shortest tone (likely a dot)
        let minDuration = toneDurations.min() ?? 0.1
        detectedUnitDuration = minDuration
    }
    
    /// Convert segments to Morse code string
    private func segmentsToMorse(segments: [(isTone: Bool, duration: Double)]) -> String {
        var morse = ""
        let unit = detectedUnitDuration
        
        for segment in segments {
            if segment.isTone {
                // Determine if dot or dash
                let units = segment.duration / unit
                if units < 2 {
                    morse += "."
                } else {
                    morse += "-"
                }
            } else {
                // Determine gap type
                let units = segment.duration / unit
                if units < 2 {
                    // Intra-character gap (ignore)
                } else if units < 5 {
                    // Inter-character gap
                    morse += " "
                } else {
                    // Word gap
                    morse += "  "
                }
            }
        }
        
        return morse
    }
    
    /// Decode from audio file
    func decodeFromFile(url: URL) async throws {
        print("🎵 MorseDecoder: Opening audio file at \(url)")
        
        let audioFile = try AVAudioFile(forReading: url)
        print("🎵 MorseDecoder: Audio file opened successfully")
        print("🎵 Format: \(audioFile.fileFormat)")
        print("🎵 Length: \(audioFile.length) frames")
        print("🎵 Duration: \(Double(audioFile.length) / audioFile.fileFormat.sampleRate) seconds")
        
        guard let buffer = AVAudioPCMBuffer(
            pcmFormat: audioFile.processingFormat,
            frameCapacity: AVAudioFrameCount(audioFile.length)
        ) else {
            throw NSError(domain: "MorseDecoder", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to create buffer"])
        }
        
        try audioFile.read(into: buffer)
        print("🎵 MorseDecoder: Audio data read into buffer")
        
        guard let channelData = buffer.floatChannelData?[0] else {
            throw NSError(domain: "MorseDecoder", code: -3, userInfo: [NSLocalizedDescriptionKey: "Failed to read audio data"])
        }
        
        recordedSamples = Array(UnsafeBufferPointer(start: channelData, count: Int(buffer.frameLength)))
        print("🎵 MorseDecoder: Recorded \(recordedSamples.count) samples")
        
        decodeMorseFromSamples()
        print("🎵 MorseDecoder: Decoding complete")
        print("🎵 Decoded morse: \(decodedMorse)")
        print("🎵 Decoded text: \(decodedText)")
    }
}
