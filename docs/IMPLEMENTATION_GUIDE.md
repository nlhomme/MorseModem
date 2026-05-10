# Implementation Guide

## Build Configuration

- **Minimum Deployment Target:** iOS 26.4 for all targets and configurations (the project-level setting in `project.pbxproj` is `26.2`, but it is overridden by every target's per-config setting — Xcode shows the effective `26.4` under each target's "Minimum Deployments").
- **Swift:** 6.0 (strict concurrency) for app + tests. `MorseModemUITests` is on Swift 5.0.
- **Universal:** `TARGETED_DEVICE_FAMILY = "1,2"` (iPhone + iPad).
- **Frameworks (system, no third-party deps):** `SwiftUI`, `SwiftData`, `AVFoundation`, `CoreHaptics`, `Accelerate`, `UniformTypeIdentifiers`, `Testing`.

### Required local file: `Config.xcconfig`

`Config.xcconfig` is gitignored — copy it from the template before building for a real device:

```bash
cp Config.xcconfig.template Config.xcconfig
# then edit DEVELOPMENT_TEAM = <your team id>
```

Simulator builds work without it.

### Schemes & build configurations

| Scheme           | Configuration   | Bundle id                          |
| ---------------- | --------------- | ---------------------------------- |
| `MorseModem`     | `Debug`/`Release` | `xyz.nlhomme.MorseModem`           |
| `MorseModem Beta`| `Beta`            | `xyz.nlhomme.MorseModem.beta`      |

The `Beta` configuration is a separate bundle id so TestFlight/dev installs can coexist with the App Store build.

## Required `Info.plist` keys

```xml
<key>NSMicrophoneUsageDescription</key>
<string>MorseModem needs access to your microphone to record and decode Morse code audio.</string>
```

For "Open in MorseModem" from other apps, `CFBundleDocumentTypes` must register the audio UTIs (already configured):

```xml
<key>CFBundleDocumentTypes</key>
<array>
  <dict>
    <key>CFBundleTypeName</key><string>Audio File</string>
    <key>CFBundleTypeRole</key><string>Viewer</string>
    <key>LSHandlerRank</key><string>Alternate</string>
    <key>LSItemContentTypes</key>
    <array>
      <string>public.audio</string>
      <string>public.mp3</string>
      <string>com.microsoft.waveform-audio</string>
      <string>public.aifc-audio</string>
      <string>public.aiff-audio</string>
      <string>com.apple.m4a-audio</string>
    </array>
  </dict>
</array>
```

`Info.plist.example` in the repo shows the full reference set including optional keys.

## Permissions

Microphone permission uses the modern API (already wired in `MorseDecoder.startRecording`):

```swift
await withCheckedContinuation { continuation in
    AVAudioApplication.requestRecordPermission { granted in
        continuation.resume(returning: granted)
    }
}
```

Don't fall back to the deprecated `AVAudioSession.requestRecordPermission` — it triggers Swift 6 concurrency warnings and is no longer the recommended path.

## Testing

Unit tests use **Swift Testing** (`import Testing`, `@Suite`, `@Test`, `#expect`) — *not* XCTest. UI tests under `MorseModemUITests/` are still XCTest.

### Run all unit tests

```bash
xcodebuild -project MorseModem.xcodeproj -scheme MorseModem \
  -destination 'platform=iOS Simulator,name=iPhone 16' test
```

### Run a single Swift Testing test

```bash
xcodebuild -project MorseModem.xcodeproj -scheme MorseModem \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:MorseModemTests/MorseEncodingTests/encodeSOSDistressSignal test
```

### Device vs Simulator

| Feature                    | Simulator       | Device   |
| -------------------------- | --------------- | -------- |
| Encoder (audio out)        | works           | works    |
| Microphone recording       | unreliable      | works    |
| Haptic feedback            | none            | works    |
| Share-sheet / "Open in…"   | partial         | works    |

For round-trip testing of the decoder, generate audio with the Encoder, export it, share it via AirDrop, and import it back into the Decoder.

## Quick Sanity Checks

```swift
// Encoder
MorseCodeMap.encode("SOS")              // "... --- ..."
MorseCodeMap.encode("HELLO WORLD")      // ".... . .-.. .-.. ---  .-- --- .-. .-.. -.."

// Decoder round-trip
MorseCodeMap.decode("... --- ...")      // "SOS"

// Timing (PARIS, 12 WPM)
let s = AppSettings(wordsPerMinute: 12)
s.dotDuration   // 0.1s
s.dashDuration  // 0.3s
s.wordGap       // 0.7s
```

## Audio Export Format

Configured in `ToneGenerator.exportMorseAudio(morse:settings:to:)`:

```swift
AVFormatIDKey         : kAudioFormatMPEG4AAC
AVSampleRateKey       : 44100
AVNumberOfChannelsKey : 1
AVEncoderBitRateKey   : 128_000
```

Files are written to `FileManager.default.temporaryDirectory` and surfaced via `ShareSheet`. The temp directory is system-managed.

## Known Gotchas

### Audio session category mismatch

The encoder switches the session to `.playback` and the decoder switches it to `.record`/`.measurement`. Don't try to record while playback is still active — `MorseDecoder.startRecording()` and `ToneGenerator.playMorse(...)` should not run concurrently.

### Haptic engine pause/resume

`CHHapticEngine` stops when the app is backgrounded or audio is interrupted. `ToneGenerator` installs `stoppedHandler`/`resetHandler` and calls `restartHapticsIfNeeded()` at the start of each playback. If you add another haptic entry point, do the same.

### Files shared into the app

`DecoderViewModel.importAudioFile(url:)` already handles the two cases — keep the contract if you refactor:

- `/Inbox/...` paths (share sheet drops files here): copy to `temporaryDirectory` first; the system can delete `/Inbox/` files at any time.
- Files outside `/Inbox/` (Files app picker): wrap reads in `startAccessingSecurityScopedResource()` / `stopAccessingSecurityScopedResource()`.

### Decoder accuracy envelope

`MorseDecoder` auto-detects the dot duration as the shortest tone, then classifies relative to it. This works well between roughly 5 and 40 WPM with a clean recording. Extreme tempos, very short messages (no shortest-tone signal), or noisy recordings will degrade.

The threshold uses `sortedEnvelope[3/4] × 0.5` — appropriate for recordings dominated by silence. If you change the recording pipeline (e.g. add AGC), revisit this.

### SwiftData settings row

Always go through `AppSettings.resolve(from:in:)` to fetch settings. It inserts a default row if none exists and saves it; constructing `AppSettings()` directly without inserting it into a context will silently lose changes.

## Localization

All user-facing strings live in `MorseModem/Localizable.xcstrings`. Use `String(localized:)` for runtime strings and `LocalizedStringKey` for views. `MorseCodeMap.allCharacters()` returns raw English category names ("Letters", "Numbers", "Punctuation") — views are responsible for localizing them.

## File Organization

Sources are flat under `MorseModem/`. There are no on-disk subgroups for Models / Services / ViewModels / Views — Xcode's project navigator may show groups but the filesystem is flat. New files only need to be added to the Xcode targets they belong to (`MorseModem` for app code, `MorseModemTests` for unit tests).

## App Store / TestFlight Checklist

- [ ] Build with `MorseModem Beta` scheme for TestFlight
- [ ] Verify `DEVELOPMENT_TEAM` in `Config.xcconfig`
- [ ] Run unit tests: `xcodebuild ... test`
- [ ] Test on iPhone + iPad (universal target)
- [ ] Verify VoiceOver announcements (see `AccessibilityNotification.Announcement` calls in `DecoderViewModel`)
- [ ] Test microphone-permission-denied path
- [ ] Test share-sheet "Open in MorseModem" from another app
- [ ] Verify Dynamic Type at largest size
