//
//  ToneGenerator.swift
//  MorseModem
//
//  Created by Nicolas Lhomme on 26/01/2026.
//

import AVFoundation
import CoreHaptics
internal import Combine

@MainActor
class ToneGenerator: NSObject, ObservableObject {
    nonisolated(unsafe) let objectWillChange = ObservableObjectPublisher()
    @Published var isPlaying = false
    
    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var hapticEngine: CHHapticEngine?
    
    private let sampleRate: Double = 44100.0
    private let fadeInOutDuration: Double = 0.005 // 5ms
    
    override init() {
        super.init()
        setupAudioSession()
        setupHaptics()
    }
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default)
            try audioSession.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    private func setupHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
        } catch {
            print("Failed to setup haptics: \(error)")
        }
    }
    
    /// Generate audio buffer for Morse code
    func generateMorseAudio(morse: String, settings: AppSettings) -> AVAudioPCMBuffer? {
        let frequency = settings.toneFrequency
        let volume = settings.volume
        
        // Calculate total duration
        var totalDuration: Double = 0
        let elements = morse.components(separatedBy: " ")
        
        for (index, element) in elements.enumerated() {
            if element.isEmpty {
                // Word gap (extra space)
                totalDuration += settings.wordGap - settings.interCharacterGap
            } else {
                for char in element {
                    if char == "." {
                        totalDuration += settings.dotDuration
                    } else if char == "-" {
                        totalDuration += settings.dashDuration
                    }
                    totalDuration += settings.intraCharacterGap
                }
                // Remove last intra-character gap, add inter-character gap
                totalDuration -= settings.intraCharacterGap
                if index < elements.count - 1 {
                    totalDuration += settings.interCharacterGap
                }
            }
        }
        
        let frameCount = AVAudioFrameCount(totalDuration * sampleRate)
        
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            return nil
        }
        
        buffer.frameLength = frameCount
        
        guard let channelData = buffer.floatChannelData?[0] else {
            return nil
        }
        
        var currentFrame = 0
        
        for element in elements {
            if element.isEmpty {
                // Word gap
                let gapFrames = Int((settings.wordGap - settings.interCharacterGap) * sampleRate)
                currentFrame += gapFrames
            } else {
                for char in element {
                    let duration: Double
                    if char == "." {
                        duration = settings.dotDuration
                    } else if char == "-" {
                        duration = settings.dashDuration
                    } else {
                        continue
                    }
                    
                    let frames = Int(duration * sampleRate)
                    let fadeFrames = Int(fadeInOutDuration * sampleRate)
                    
                    for i in 0..<frames {
                        let phase = 2.0 * Double.pi * frequency * Double(i) / sampleRate
                        var sample = Float(sin(phase) * volume)
                        
                        // Apply fade in/out
                        if i < fadeFrames {
                            sample *= Float(i) / Float(fadeFrames)
                        } else if i > frames - fadeFrames {
                            sample *= Float(frames - i) / Float(fadeFrames)
                        }
                        
                        if currentFrame < frameCount {
                            channelData[currentFrame] = sample
                            currentFrame += 1
                        }
                    }
                    
                    // Intra-character gap
                    let gapFrames = Int(settings.intraCharacterGap * sampleRate)
                    currentFrame += gapFrames
                }
                
                // Inter-character gap (compensate for intra-character gap)
                let gapFrames = Int((settings.interCharacterGap - settings.intraCharacterGap) * sampleRate)
                currentFrame += gapFrames
            }
        }
        
        return buffer
    }
    
    /// Play Morse code audio
    func playMorse(_ morse: String, settings: AppSettings) async {
        guard !isPlaying else { return }
        
        isPlaying = true
        
        guard let buffer = generateMorseAudio(morse: morse, settings: settings) else {
            isPlaying = false
            return
        }
        
        audioEngine = AVAudioEngine()
        playerNode = AVAudioPlayerNode()
        
        guard let audioEngine = audioEngine, let playerNode = playerNode else {
            isPlaying = false
            return
        }
        
        audioEngine.attach(playerNode)
        audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: buffer.format)
        
        do {
            try audioEngine.start()
            
            // Play haptic feedback concurrently
            async let hapticTask: Void = playHapticPattern(morse: morse, settings: settings)
            
            // Schedule buffer with completion handler and wait for it to finish
            await withCheckedContinuation { continuation in
                playerNode.scheduleBuffer(buffer) {
                    continuation.resume()
                }
                playerNode.play()
            }
            
            await hapticTask
            
            isPlaying = false
            audioEngine.stop()
            
        } catch {
            print("Failed to play audio: \(error)")
            isPlaying = false
        }
    }
    
    /// Stop playing
    func stop() {
        playerNode?.stop()
        audioEngine?.stop()
        isPlaying = false
    }
    
    /// Play haptic pattern for Morse code
    private func playHapticPattern(morse: String, settings: AppSettings) async {
        guard let hapticEngine = hapticEngine else { return }
        
        var events: [CHHapticEvent] = []
        var currentTime: TimeInterval = 0
        
        let elements = morse.components(separatedBy: " ")
        
        for element in elements {
            if element.isEmpty {
                currentTime += settings.wordGap - settings.interCharacterGap
            } else {
                for char in element {
                    let duration: Double
                    let intensity: Float
                    
                    if char == "." {
                        duration = settings.dotDuration
                        intensity = 0.5
                    } else if char == "-" {
                        duration = settings.dashDuration
                        intensity = 0.8
                    } else {
                        continue
                    }
                    
                    let event = CHHapticEvent(
                        eventType: .hapticTransient,
                        parameters: [
                            CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity)
                        ],
                        relativeTime: currentTime
                    )
                    events.append(event)
                    
                    currentTime += duration + settings.intraCharacterGap
                }
                
                currentTime += settings.interCharacterGap - settings.intraCharacterGap
            }
        }
        
        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try hapticEngine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            print("Failed to play haptic pattern: \(error)")
        }
    }
    
    /// Export audio to file
    func exportMorseAudio(morse: String, settings: AppSettings, to url: URL) async throws {
        guard let buffer = generateMorseAudio(morse: morse, settings: settings) else {
            throw NSError(domain: "ToneGenerator", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to generate audio"])
        }
        
        let audioFile = try AVAudioFile(forWriting: url, settings: [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: sampleRate,
            AVNumberOfChannelsKey: 1,
            AVEncoderBitRateKey: 128000
        ])
        
        try audioFile.write(from: buffer)
    }
}
