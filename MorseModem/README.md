# MorseModem - iOS Morse Code Encoder/Decoder

A modern iOS app that converts text to Morse code audio and decodes Morse code audio back to text.

## Features

### ✨ Core Functionality

- **Text to Morse Encoder**
  - Real-time Morse code translation
  - Audio playback with sine wave generation
  - Export to M4A audio files
  - Haptic feedback during playback
  - Adjustable tone frequency, speed (WPM), and volume

- **Morse Code Decoder**
  - Record Morse code directly from microphone
  - Import audio files from Files app
  - Real-time waveform visualization
  - Automatic speed detection
  - Noise gate for background noise filtering

- **Morse Code Reference**
  - Searchable character reference
  - Letters A-Z, Numbers 0-9, Punctuation
  - Tap to play individual character sounds
  - Organized by category

- **Message History**
  - Automatic saving of encoded/decoded messages
  - Search functionality
  - Detailed message view
  - Copy to clipboard

## Technical Implementation

### Audio Generation

The app uses **AVFoundation** to generate high-quality sine wave tones:

- Sample rate: 44,100 Hz
- Fade in/out: 5ms to prevent clicking
- Default frequency: 700 Hz (adjustable 300-1500 Hz)

**Timing Standards (based on WPM):**
- Dot: 1 unit
- Dash: 3 units
- Intra-character gap: 1 unit
- Inter-character gap: 3 units
- Word gap: 7 units

### Audio Decoding

The decoder uses advanced signal processing:

1. **Envelope Detection**: RMS amplitude calculation over sliding windows
2. **Threshold Detection**: Automatic threshold calculation for tone vs. silence
3. **Timing Analysis**: Auto-detection of dot duration for speed adaptation
4. **Pattern Recognition**: Conversion of timing patterns to dots and dashes

### Data Persistence

Using **SwiftData** for local storage:

- `Message`: Stores encoded/decoded message history
- `AppSettings`: Persists user preferences (frequency, speed, volume)

### Haptic Feedback

Integrated **CoreHaptics** for enhanced user experience:
- Different intensities for dots (lighter) vs. dashes (stronger)
- Synchronized with audio playback

## Architecture

```
MorseModem/
├── Models/
│   ├── MorseCodeMap.swift       # Character ↔ Morse mappings
│   ├── Message.swift            # Message history model
│   └── AppSettings.swift        # User preferences model
├── Services/
│   ├── ToneGenerator.swift      # Audio generation & playback
│   └── MorseDecoder.swift       # Audio analysis & decoding
├── ViewModels/
│   ├── EncoderViewModel.swift   # Encoder business logic
│   └── DecoderViewModel.swift   # Decoder business logic
├── Views/
│   ├── ContentView.swift        # Main tab container
│   ├── EncoderView.swift        # Text to Morse encoder UI
│   ├── DecoderView.swift        # Morse to text decoder UI
│   ├── ReferenceView.swift      # Character reference UI
│   ├── HistoryView.swift        # Message history UI
│   ├── SettingsView.swift       # Settings configuration UI
│   └── ShareSheet.swift         # iOS share sheet wrapper
└── Tests/
    └── MorseModemTests.swift    # Unit tests
```

## Requirements

- iOS 17.0+ (uses SwiftData and modern SwiftUI APIs)
- Microphone permission (for audio recording)
- Files access (for audio import)

## Accessibility

The app is designed with accessibility in mind:

- **VoiceOver**: All controls have descriptive labels
- **Dynamic Type**: Text scales with system settings
- **Haptic Feedback**: Non-audio feedback for hearing-impaired users
- **High Contrast**: Works well in both Light and Dark modes

## Testing

The app includes comprehensive unit tests using Swift Testing framework:

- Morse code encoding/decoding validation
- Timing calculations verification
- Round-trip encoding/decoding tests
- Character mapping consistency checks

Run tests with: `Cmd+U` in Xcode

## Privacy

- All processing is done on-device
- No data collection or analytics
- Microphone access only when recording
- Audio files stored locally

## Future Enhancements

Potential features for future versions:

- [ ] Apple Watch companion app
- [ ] Flashlight Morse code mode
- [ ] Widget for quick encoding
- [ ] Siri Shortcuts integration
- [ ] iCloud sync for history
- [ ] iPad optimizations with split-view
- [ ] macOS version with menu bar access
- [ ] Custom training mode to learn Morse code
- [ ] Multi-language support

## Development Notes

### Audio Export Format

The app exports audio in M4A format (AAC codec) for optimal file size and compatibility. Settings:
- Format: MPEG-4 AAC
- Sample rate: 44,100 Hz
- Channels: Mono (1)
- Bit rate: 128 kbps

### Morse Code Standards

The implementation follows International Morse Code standards with the PARIS timing method for WPM calculations.

### Performance Considerations

- Audio generation uses efficient buffer-based synthesis
- Waveform display is downsampled to 1000 points for smooth rendering
- Real-time decoding uses sliding window analysis (512 samples)
- History is loaded on-demand using SwiftData's lazy loading

## License

Copyright © 2026 Nicolas Lhomme. All rights reserved.

## Credits

Built with:
- SwiftUI for modern, declarative UI
- SwiftData for persistent storage
- AVFoundation for audio processing
- CoreHaptics for tactile feedback
- Swift Testing for unit tests
