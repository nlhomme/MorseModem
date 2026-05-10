# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

MorseModem is a SwiftUI iOS/iPadOS app (universal, `TARGETED_DEVICE_FAMILY = "1,2"`) that encodes text to Morse code audio and decodes Morse audio back to text. Pure Xcode project — no SPM, CocoaPods, or external package dependencies. Swift 6 strict concurrency.

## Build & test

The project requires a `Config.xcconfig` file (gitignored, copy from `Config.xcconfig.template`) supplying `DEVELOPMENT_TEAM` before it will build for a real device.

Schemes/configs:
- Schemes: `MorseModem` (Debug/Release) and `MorseModem Beta` (Beta config — separate bundle id `xyz.nlhomme.MorseModem.beta`).
- Build configurations: `Debug`, `Release`, `Beta`.
- Targets: `MorseModem`, `MorseModemTests` (unit), `MorseModemUITests`.

Common commands (run from repo root):

```bash
# Build for simulator
xcodebuild -project MorseModem.xcodeproj -scheme MorseModem -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 16' build

# Run all unit tests
xcodebuild -project MorseModem.xcodeproj -scheme MorseModem \
  -destination 'platform=iOS Simulator,name=iPhone 16' test

# Run a single Swift Testing test (uses Swift Testing, NOT XCTest — filter by suite/test name)
xcodebuild -project MorseModem.xcodeproj -scheme MorseModem \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:MorseModemTests/MorseEncodingTests/encodeSOSDistressSignal test
```

Tests use Apple's **Swift Testing** framework (`import Testing`, `@Test`, `@Suite`, `#expect`) — not XCTest. Don't add `XCTestCase` subclasses to `MorseModemTests/`. UI tests under `MorseModemUITests/` still use XCTest.

## Architecture

MVVM with `@Observable` view models and SwiftData-backed persistence. The whole app is `@MainActor`-bound except the pure encoding/decoding logic and audio buffer math.

```
MorseModemApp ─▶ ContentView (TabView) ─▶ {Encoder, Decoder, Reference, History}
                       │
                       ├─ EncoderView ─▶ EncoderViewModel ─▶ ToneGenerator (AVAudioEngine + CoreHaptics)
                       └─ DecoderView ─▶ DecoderViewModel ─▶ MorseDecoder    (AVAudioEngine)
                                                  │
                                                  ▼
                                          MorseCodeMap (pure, nonisolated)
                                                  │
                                          SwiftData: Message, AppSettings
```

Key files (the real source of truth — the markdown files under `docs/` and `MorseModem.xcodeproj/` are historical design notes and may lag behind the code):

- `MorseModem/MorseModemApp.swift` — `@main` entry, builds the shared `ModelContainer` for `Message` + `AppSettings`, wires `.onOpenURL` into `sharedAudioURL` (drives "Open in MorseModem" share-sheet imports).
- `MorseModem/ContentView.swift` — 4-tab layout. When `sharedAudioURL` becomes non-nil, switches to the Decoder tab.
- `MorseModem/MorseCodeMap.swift` — pure encode/decode. Uses `nonisolated(unsafe)` static dictionaries so the maps can be read off the main actor under Swift 6 strict concurrency. The encoder splits text into words and joins them with **double-space**; decoder splits on double-space for word boundaries — preserve this convention if you touch either side.
- `MorseModem/AppSettings.swift` — `@Model` storing `toneFrequency`, `wordsPerMinute`, `volume`. Computed properties (`dotDuration`, `dashDuration`, `intra/inter/wordGap`) implement standard PARIS-timing WPM (`60 / (50 * wpm)` seconds per dot). Read these computed values rather than recomputing timings inline.
- `MorseModem/ToneGenerator.swift` — generates a single PCM buffer for the entire morse string (sine wave at `toneFrequency`, 5 ms fade in/out per element to avoid clicks), schedules it on `AVAudioPlayerNode`, and plays a parallel `CHHapticPattern` (intensity 0.5 for dots, 0.8 for dashes). Handles haptic-engine `stoppedHandler` / `resetHandler` (engine restarts after backgrounding via `restartHapticsIfNeeded()`); audio session is set to `.playback`.
- `MorseModem/MorseDecoder.swift` — records via `AVAudioEngine` input tap (audio session `.record`/`.measurement`), keeps the live waveform downsampled to `maxWaveformSamples = 1000` RMS values, then on stop runs: RMS envelope (sliding 512-sample window) → adaptive threshold (`sortedEnvelope[3/4] * 0.5`) → tone/silence segments → auto-detect dot duration as `min(toneDurations)` → segments-to-morse. The 2u/5u classification is asymmetric: tones split at 2u (`<2u` dot, `≥2u` dash — no upper bound); silences split at both 2u and 5u (`<2u` intra-gap, `2–5u` inter-char, `>5u` word gap).
- `MorseModem/Localizable.xcstrings` — UI strings; user-visible strings should go through `String(localized:)` / `LocalizedStringKey`. `MorseCodeMap.allCharacters()` returns raw English category names (`"Letters"`, `"Numbers"`, `"Punctuation"`) that the views localize via `LocalizedStringKey`.

## Conventions worth knowing

- View models are `@MainActor @Observable` and own their service objects (`ToneGenerator`, `MorseDecoder`). They receive `ModelContext` via init, not via `@Environment`.
- SwiftData persistence: settings are resolved via `AppSettings.resolve(from:in:)` which inserts a default row if none exists — use this rather than instantiating settings directly.
- Audio file imports from the Files app / share sheet: see `DecoderViewModel.importAudioFile(url:)`. `/Inbox/` files must be copied to `temporaryDirectory` before reading (system can clean them up); files outside `/Inbox/` need `startAccessingSecurityScopedResource()`.
- Microphone permission must be requested via `AVAudioApplication.requestRecordPermission` (the modern API) before starting the engine — `MorseDecoder.startRecording()` already does this.
- `Info.plist` requires `NSMicrophoneUsageDescription`; document-type registration for `public.audio` etc. is what enables "Open in MorseModem" from other apps.
- Legacy design notes live in `docs/` (`ARCHITECTURE.md`, `IMPLEMENTATION_GUIDE.md`) and `MorseModem.xcodeproj/` (`RECORDING_UI_*.md`, `AUDIO_IMPORT_*.md`, `SHARE_SHEET_TROUBLESHOOTING.md`). Treat them as historical context only — verify against current code before relying on any specific claim.

## Keep documentation current

`CLAUDE.md`, `README.md`, and everything under `docs/` are part of the codebase, not historical notes. Whenever a change invalidates something they say — a renamed file, a moved threshold, a new dependency, a deployment-target bump, a removed feature, a new convention — update the relevant doc in the same change. After non-trivial work, do a quick pass to confirm these files still match reality.
