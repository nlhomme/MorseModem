# MorseModem

A SwiftUI iOS / iPadOS app that encodes text to Morse code audio and decodes Morse audio back to text. On-device, no network, no third-party dependencies.

## Features

- **Encoder** — text → Morse audio. Sine-wave tone with 5 ms fade in/out, parallel haptic pattern (lighter for dots, stronger for dashes), export to AAC `.m4a`.
- **Decoder** — record from the microphone or import an audio file (Files app, AirDrop, "Open in MorseModem" share sheet). Live RMS waveform; auto-detects the sender's WPM from the shortest tone.
- **Reference** — searchable table of letters, numbers, and punctuation; tap a row to hear it.
- **History** — every encoded/decoded message persists via SwiftData; searchable and copyable.

Settings: tone frequency, words-per-minute (PARIS timing), volume.

## Requirements

- **iOS / iPadOS 26.2** (`MorseModem` scheme) or **26.4** (`MorseModem Beta` scheme)
- Xcode supporting Swift 6 strict concurrency
- Microphone permission (recording) and Files access (audio import) — requested at first use

## Building

```bash
# 1. Configure your team
cp Config.xcconfig.template Config.xcconfig
# edit DEVELOPMENT_TEAM = <your team id>

# 2. Build for simulator
xcodebuild -project MorseModem.xcodeproj -scheme MorseModem -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 16' build

# 3. Run unit tests
xcodebuild -project MorseModem.xcodeproj -scheme MorseModem \
  -destination 'platform=iOS Simulator,name=iPhone 16' test
```

`Config.xcconfig` is gitignored. Simulator builds work without a team id.

Schemes:

| Scheme            | Configuration     | Bundle id                       |
| ----------------- | ----------------- | ------------------------------- |
| `MorseModem`      | `Debug`/`Release` | `xyz.nlhomme.MorseModem`        |
| `MorseModem Beta` | `Beta`            | `xyz.nlhomme.MorseModem.beta`   |

## Tech

- **SwiftUI** + `@Observable` view models, MVVM, `@MainActor`-bound app
- **SwiftData** for `Message` history and `AppSettings`
- **AVFoundation** (`AVAudioEngine`, `AVAudioPlayerNode`) for tone synthesis and capture
- **CoreHaptics** for synchronized tactile feedback
- **Accelerate** imported for envelope math
- **Swift Testing** (`@Suite`/`@Test`/`#expect`) for unit tests; XCTest for UI tests

All processing runs on-device. No analytics, no network calls.

## Project layout

Sources are flat under `MorseModem/` — no on-disk subgroups for Models / Services / Views.

```
MorseModem/             // App sources (Swift, Assets, Localizable.xcstrings, Info.plist)
MorseModemTests/        // Swift Testing unit tests
MorseModemUITests/      // XCTest UI tests
docs/                   // Architecture + implementation docs
assets/                 // App icon source SVGs and screenshots
Config.xcconfig.template
```

For the why behind the code (audio pipeline, decoder thresholds, share-sheet plumbing, Swift 6 concurrency notes), see:

- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md)
- [`docs/IMPLEMENTATION_GUIDE.md`](docs/IMPLEMENTATION_GUIDE.md)
- [`CLAUDE.md`](CLAUDE.md) — orientation notes for working in this repo

## Accessibility

VoiceOver labels on all controls, `AccessibilityNotification.Announcement` calls around recording state changes, Dynamic Type, light/dark modes. Haptics provide non-audio feedback during encoder playback.

## License

Licensed under the [PolyForm Noncommercial License 1.0.0](LICENSE) — free to use, modify, and redistribute for any noncommercial purpose. Commercial use is not permitted; for a commercial license, contact the author.

Copyright © 2026 Nicolas Lhomme.
