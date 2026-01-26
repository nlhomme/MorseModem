# MorseModem Architecture Diagram

## App Structure

```
┌─────────────────────────────────────────────────────────────┐
│                      MorseModemApp                          │
│                   (SwiftUI App Entry)                       │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                     ContentView                             │
│                  (TabView Container)                        │
├────────────┬────────────┬────────────┬──────────────────────┤
│  Encoder   │  Decoder   │ Reference  │     History         │
│    Tab     │    Tab     │    Tab     │      Tab            │
└────────────┴────────────┴────────────┴──────────────────────┘
```

## Encoder Flow

```
┌──────────────┐      ┌──────────────────┐      ┌─────────────────┐
│ EncoderView  │─────▶│ EncoderViewModel │─────▶│ ToneGenerator   │
│  (SwiftUI)   │      │   (@Observable)  │      │  (Audio Engine) │
└──────┬───────┘      └────────┬─────────┘      └────────┬────────┘
       │                       │                          │
       │ User Input            │ Business Logic           │ Audio Output
       │                       │                          │
       ▼                       ▼                          ▼
 Text Input           MorseCodeMap.encode()        AVAudioEngine
 Settings UI          Save to History              CoreHaptics
 Play/Export          Share Files                  Audio Export
```

## Decoder Flow

```
┌──────────────┐      ┌──────────────────┐      ┌─────────────────┐
│ DecoderView  │─────▶│ DecoderViewModel │─────▶│  MorseDecoder   │
│  (SwiftUI)   │      │   (@Observable)  │      │  (Audio Engine) │
└──────┬───────┘      └────────┬─────────┘      └────────┬────────┘
       │                       │                          │
       │ User Actions          │ Business Logic           │ Audio Input
       │                       │                          │
       ▼                       ▼                          ▼
 Record/Import         MorseCodeMap.decode()       AVAudioEngine
 Waveform Display      Save to History             Signal Processing
 Copy/Clear            File Import                 Pattern Recognition
```

## Data Models (SwiftData)

```
┌────────────────────────────────────────────────────────┐
│                    SwiftData Store                     │
├────────────────────────┬───────────────────────────────┤
│      Message           │       AppSettings             │
├────────────────────────┼───────────────────────────────┤
│ • text: String         │ • toneFrequency: Double       │
│ • morseCode: String    │ • wordsPerMinute: Int         │
│ • timestamp: Date      │ • volume: Double              │
│ • isEncoded: Bool      │ • (computed timing values)    │
└────────────────────────┴───────────────────────────────┘
```

## Service Layer

```
┌─────────────────────────────────────────────────────────────┐
│                      Audio Services                         │
├─────────────────────────────┬───────────────────────────────┤
│      ToneGenerator          │       MorseDecoder            │
├─────────────────────────────┼───────────────────────────────┤
│ • Generate sine waves       │ • Record from microphone      │
│ • Apply timing (WPM)        │ • Import audio files          │
│ • Add fade in/out           │ • Compute amplitude envelope  │
│ • Play with haptics         │ • Detect tone/silence         │
│ • Export to M4A             │ • Auto-detect timing          │
│                             │ • Pattern recognition         │
└─────────────────────────────┴───────────────────────────────┘
```

## Utility Layer

```
┌─────────────────────────────────────────────────────────────┐
│                     MorseCodeMap                            │
├─────────────────────────────────────────────────────────────┤
│ • charToMorse: [Character: String]  (A → ".-")             │
│ • morseToChar: [String: Character]  (".-" → A)             │
│ • encode(text) → morse code                                 │
│ • decode(morse) → text                                      │
│ • allCharacters() → categorized list                        │
└─────────────────────────────────────────────────────────────┘
```

## User Interaction Flow

### Encoding Flow
```
1. User types text
   ↓
2. EncoderViewModel.updateMorseCode()
   ↓
3. MorseCodeMap.encode(text)
   ↓
4. Display morse code in UI
   ↓
5. User taps "Play"
   ↓
6. ToneGenerator.playMorse()
   ↓
7. Generate audio buffer (sine waves)
   ↓
8. Play audio + haptics simultaneously
   ↓
9. Save to Message history
```

### Decoding Flow
```
1. User taps "Start Recording"
   ↓
2. Request microphone permission
   ↓
3. MorseDecoder.startRecording()
   ↓
4. AVAudioEngine captures audio
   ↓
5. Process buffers in real-time
   ↓
6. Update waveform visualization
   ↓
7. User taps "Stop Recording"
   ↓
8. MorseDecoder.stopRecording()
   ↓
9. Analyze recorded samples
   ↓
10. Detect envelope & segments
    ↓
11. Auto-detect timing unit
    ↓
12. Convert to morse code
    ↓
13. MorseCodeMap.decode(morse)
    ↓
14. Display text + save to history
```

## State Management

```
┌─────────────────────────────────────────────────────────────┐
│                    @Observable Pattern                      │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ViewModel (Source of Truth)                                │
│       ↓                                                      │
│  @Published properties                                       │
│       ↓                                                      │
│  View automatically updates                                  │
│       ↓                                                      │
│  User interaction triggers ViewModel methods                │
│       ↓                                                      │
│  ViewModel updates properties                                │
│       ↓                                                      │
│  Cycle repeats                                               │
└─────────────────────────────────────────────────────────────┘
```

## Audio Processing Pipeline

### Tone Generation (Encoder)
```
Text Input
   ↓
MorseCodeMap.encode() → "... --- ..."
   ↓
For each character:
   • Calculate duration (based on WPM)
   • Dot = 1 unit, Dash = 3 units
   • Gaps: intra=1, inter=3, word=7
   ↓
Generate samples:
   • Sample rate: 44100 Hz
   • Sine wave: sin(2π × freq × time)
   • Apply fade: 5ms in/out
   • Normalize: multiply by volume
   ↓
Create AVAudioPCMBuffer
   ↓
Schedule in AVAudioPlayerNode
   ↓
Play audio
```

### Signal Decoding (Decoder)
```
Microphone/File Input
   ↓
AVAudioEngine captures samples (Float array)
   ↓
Compute Envelope:
   • Sliding window (512 samples)
   • Calculate RMS amplitude
   • Downsample for analysis
   ↓
Detect Segments:
   • Auto-detect threshold (75th percentile)
   • Classify: tone vs silence
   • Measure duration of each
   ↓
Auto-detect Timing:
   • Find shortest tone (dot)
   • Use as unit duration
   ↓
Pattern Recognition:
   • tone < 2 units = dot (.)
   • tone ≥ 2 units = dash (-)
   • silence < 2 units = intra-char (ignore)
   • silence 2-5 units = inter-char (space)
   • silence > 5 units = word gap (double space)
   ↓
Generate morse string: "... --- ..."
   ↓
MorseCodeMap.decode() → "SOS"
   ↓
Display text
```

## Memory Management

```
┌─────────────────────────────────────────────────────────────┐
│                    Memory Usage                             │
├─────────────────────────────────────────────────────────────┤
│ Audio Buffers:         Temporary (released after play)      │
│ Recorded Samples:      Limited to recording duration        │
│ Waveform Data:         Max 1000 points (circular buffer)    │
│ Message History:       SwiftData lazy loading               │
│ Audio Files:           Temporary directory (auto-cleanup)   │
│ Settings:              Single instance (lightweight)         │
└─────────────────────────────────────────────────────────────┘
```

## Threading Model

```
┌─────────────────────────────────────────────────────────────┐
│                    Concurrency                              │
├─────────────────────────────────────────────────────────────┤
│ @MainActor:            All ViewModels and UI                │
│ async/await:           Audio processing tasks               │
│ AVAudioEngine:         Separate audio thread (internal)     │
│ SwiftData:             Background context for heavy ops     │
│ File I/O:              Async operations                      │
└─────────────────────────────────────────────────────────────┘
```

## Error Handling

```
User Action
   ↓
Try operation
   ├─ Success → Update UI
   │
   └─ Failure → Catch error
              ↓
         Set error state
              ↓
         Show alert to user
              ↓
         User dismisses
              ↓
         Reset error state
```

## File Organization in Xcode

```
MorseModem/
├── 📁 App
│   └── MorseModemApp.swift
│
├── 📁 Models
│   ├── MorseCodeMap.swift
│   ├── Message.swift
│   └── AppSettings.swift
│
├── 📁 ViewModels
│   ├── EncoderViewModel.swift
│   └── DecoderViewModel.swift
│
├── 📁 Views
│   ├── ContentView.swift
│   ├── EncoderView.swift
│   ├── DecoderView.swift
│   ├── ReferenceView.swift
│   ├── HistoryView.swift
│   ├── SettingsView.swift
│   └── ShareSheet.swift
│
├── 📁 Services
│   ├── ToneGenerator.swift
│   └── MorseDecoder.swift
│
└── 📁 Tests
    └── MorseModemTests.swift
```

## Dependency Graph

```
Views
  ↓ depend on
ViewModels
  ↓ depend on
Services + Models
  ↓ depend on
System Frameworks (AVFoundation, CoreHaptics, SwiftData)
```

## Key Design Patterns

1. **MVVM (Model-View-ViewModel)**
   - Clear separation of concerns
   - Views are declarative
   - ViewModels handle business logic
   - Models represent data

2. **Observable Pattern**
   - ViewModels are @Observable
   - Views automatically update
   - No manual view refresh needed

3. **Dependency Injection**
   - ModelContext passed to ViewModels
   - Settings passed to services
   - Testable and flexible

4. **Service Layer**
   - Audio operations encapsulated
   - Reusable across views
   - Easy to test independently

5. **Protocol-Oriented (Future)**
   - Could add protocols for audio services
   - Would enable mocking in tests
   - Better for dependency injection

## Performance Considerations

```
┌─────────────────────────────────────────────────────────────┐
│                   Optimization Points                       │
├─────────────────────────────────────────────────────────────┤
│ ✓ Buffer-based audio synthesis (not sample-by-sample)      │
│ ✓ Downsampled waveform display (1000 points max)           │
│ ✓ Lazy loading with SwiftData @Query                        │
│ ✓ Temporary file cleanup after export                       │
│ ✓ Audio engine reuse where possible                         │
│ ✓ Efficient RMS calculation with Accelerate (future)        │
└─────────────────────────────────────────────────────────────┘
```

---

This architecture provides:
- Clear separation of concerns
- Easy testing
- Maintainable code
- Good performance
- Extensibility for future features
