# Implementation Guide & Known Issues

## Setup Instructions

### 1. Add Required Permissions to Info.plist

The app requires microphone access. Add this to your `Info.plist`:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>MorseModem needs access to your microphone to record and decode Morse code audio.</string>
```

### 2. Build Configuration

- **Minimum Deployment Target:** iOS 17.0
- **Swift Version:** Swift 5.9+
- **Required Frameworks:**
  - AVFoundation
  - CoreHaptics
  - SwiftUI
  - SwiftData

### 3. File Organization in Xcode

Make sure to add all created files to your Xcode project:

**Models:**
- MorseCodeMap.swift
- Message.swift
- AppSettings.swift

**Services:**
- ToneGenerator.swift
- MorseDecoder.swift

**ViewModels:**
- EncoderViewModel.swift
- DecoderViewModel.swift

**Views:**
- ContentView.swift (updated)
- EncoderView.swift
- DecoderView.swift
- ReferenceView.swift
- HistoryView.swift
- SettingsView.swift
- ShareSheet.swift

**App:**
- MorseModemApp.swift (updated)

**Tests:**
- MorseModemTests.swift (updated)

## Testing on Device vs Simulator

### Audio Recording (Decoder)
⚠️ **Important:** Audio recording requires a physical device. The simulator doesn't support microphone input well.

**Simulator Limitations:**
- Microphone recording may not work
- Haptic feedback won't work
- Audio quality may be poor

**Recommended Testing:**
- Use physical iPhone/iPad for full testing
- Simulator can be used for UI testing and encoder functionality

### Testing the Decoder
To test decoder functionality:

1. Generate test audio on the encoder
2. Export the audio file
3. Share it via AirDrop to your Mac or another device
4. Import it back into the decoder

## Known Issues & Workarounds

### 1. Audio Session Conflicts

**Issue:** If multiple audio sessions are active, playback might fail.

**Workaround:** The app properly configures audio sessions, but if issues arise:
```swift
// Manually reset audio session
try? AVAudioSession.sharedInstance().setActive(false)
try? AVAudioSession.sharedInstance().setActive(true)
```

### 2. Decoder Sensitivity

**Issue:** Decoder might not detect very fast or very slow Morse code accurately.

**Current Support:**
- Optimal: 10-20 WPM
- Acceptable: 5-40 WPM
- Outside this range: May require manual adjustment

**Future Enhancement:** Add manual threshold adjustment in decoder settings.

### 3. Background Audio

**Current Behavior:** Audio stops when app goes to background.

**To Enable Background Audio:** Add Background Modes capability and audio session configuration:
```swift
try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers])
```

### 4. Haptic Feedback on Older Devices

**Issue:** Haptic feedback requires devices with Taptic Engine.

**Affected Devices:** 
- Devices without Taptic Engine will play audio without haptics
- App gracefully handles this with `CHHapticEngine.capabilitiesForHardware()`

### 5. File Export on Simulator

**Issue:** Share sheet works differently on simulator.

**Workaround:** Test file export features on a real device for accurate behavior.

## Performance Optimization Tips

### 1. Audio Buffer Size
The current buffer size (4096) balances latency and performance. Adjust if needed:
```swift
inputNode?.installTap(onBus: 0, bufferSize: 2048, format: inputFormat) // Lower latency
```

### 2. Waveform Data Limit
The waveform display is limited to 1000 samples. Increase if you want longer visualization:
```swift
if waveformData.count < 2000 { // More historical data
```

### 3. Message History
SwiftData automatically handles pagination. For very large histories (1000+ messages), consider:
- Adding pagination to HistoryView
- Implementing automatic cleanup of old messages

## Debugging Tips

### Enable Audio Logging
Add this to see detailed audio information:
```swift
print("Audio format: \(audioEngine.inputNode.inputFormat(forBus: 0))")
print("Sample rate: \(audioEngine.inputNode.inputFormat(forBus: 0).sampleRate)")
```

### Test Morse Encoding
Quick test in Xcode console:
```swift
let morse = MorseCodeMap.encode("SOS")
print(morse) // Should print: "... --- ..."
```

### Verify Timing Calculations
```swift
let settings = AppSettings(wordsPerMinute: 12)
print("Dot: \(settings.dotDuration)s") // Should be ~0.1s
print("Dash: \(settings.dashDuration)s") // Should be ~0.3s
```

## iPad Optimization

The current implementation works on iPad but could be enhanced:

### Suggested Improvements:
1. Use `NavigationSplitView` for iPad instead of `TabView`
2. Side-by-side encoder and decoder views
3. Larger waveform display
4. Keyboard shortcuts for common actions

### Example iPad Layout:
```swift
#if os(iOS)
if UIDevice.current.userInterfaceIdiom == .pad {
    NavigationSplitView {
        Sidebar()
    } detail: {
        DetailView()
    }
} else {
    TabView { ... }
}
#endif
```

## Accessibility Improvements

### Current Implementation:
✅ VoiceOver labels on all buttons
✅ Dynamic Type support
✅ Haptic feedback for non-audio feedback
✅ High contrast support

### Suggested Enhancements:
- Voice Control custom commands
- Larger touch targets option
- Custom color scheme for colorblind users
- Audio descriptions for waveform visualization

## App Store Submission Checklist

Before submitting to the App Store:

- [ ] Test on multiple device sizes (iPhone SE, Pro, Pro Max, iPad)
- [ ] Test with VoiceOver enabled
- [ ] Test with Dynamic Type at maximum size
- [ ] Test in both Light and Dark modes
- [ ] Verify privacy policy mentions microphone usage
- [ ] Test all share sheet functionality
- [ ] Verify audio export works correctly
- [ ] Test with low storage space
- [ ] Test with microphone permission denied
- [ ] Verify all error messages are user-friendly

## Additional Features to Consider

### Educational Mode
Add a learning mode that:
- Shows Morse code character by character
- Provides practice exercises
- Tracks learning progress

### Custom Patterns
Allow users to:
- Create custom Morse-like patterns
- Save favorite messages as templates
- Quick-access to emergency codes (SOS, MAYDAY)

### Social Features
- Share Morse code as visual (dots/dashes)
- Generate QR codes with Morse patterns
- Morse code challenges with friends

### Advanced Audio Processing
- Multiple frequency detection (for QRM filtering)
- Adaptive noise cancellation
- Audio spectrum analyzer view

## Useful Testing Codes

Here are some test messages:

**SOS (Emergency):** `SOS`
**Morse:** `... --- ...`

**HELLO WORLD**
**Morse:** `.... . .-.. .-.. ---  .-- --- .-. .-.. -..`

**THE QUICK BROWN FOX**
**Morse:** `- .... .  --.- ..- .. -.-. -.-  -... .-. --- .-- -.  ..-. --- -..-`

**Numbers 0-9**
**Morse:** `----- .---- ..--- ...-- ....- ..... -.... --... ---.. ----.`

**PARIS (WPM Standard)**
**Morse:** `.--. .- .-. .. ...`

## Support Resources

- **Morse Code Standard:** ITU-R M.1677-1
- **WPM Calculation:** PARIS method (50 units = 1 word)
- **Audio Format Reference:** AAC-LC codec documentation
- **AVFoundation Guide:** Apple Developer Documentation
- **SwiftData Guide:** Apple Developer Documentation

## Contact & Contributions

For bugs, feature requests, or contributions:
- File issues in the repository
- Follow Swift and SwiftUI best practices
- Include unit tests for new features
- Update documentation for changes

---

**Last Updated:** January 26, 2026
**Version:** 1.0.0
**Minimum iOS:** 17.0
