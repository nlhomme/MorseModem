# MorseModem Architecture

## App Structure

```
┌─────────────────────────────────────────────────────────────┐
│                      MorseModemApp                          │
│  • @main entry, builds shared SwiftData ModelContainer       │
│  • .onOpenURL → @State sharedAudioURL (drives "Open in…")    │
│  • Shows SplashScreenView for 1.5s on launch                 │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                     ContentView                             │
│  TabView; switches to Decoder tab when sharedAudioURL set    │
├────────────┬────────────┬────────────┬──────────────────────┤
│  Encoder   │  Decoder   │ Reference  │     History          │
│    Tab     │    Tab     │    Tab     │      Tab             │
└────────────┴────────────┴────────────┴──────────────────────┘
```

## Encoder Flow

```
┌──────────────┐      ┌──────────────────┐      ┌─────────────────┐
│ EncoderView  │─────▶│ EncoderViewModel │─────▶│ ToneGenerator   │
│  (SwiftUI)   │      │   (@Observable)  │      │  (AVAudioEngine)│
└──────┬───────┘      └────────┬─────────┘      └────────┬────────┘
       │                       │                          │
       ▼                       ▼                          ▼
 Text Input           MorseCodeMap.encode()        Sine-wave PCM buffer
 Settings UI          Save Message to history      AVAudioPlayerNode
 Play / Export        Export to temp .m4a          CHHapticPattern (parallel)
                      ShareSheet for export        Audio session: .playback
```

## Decoder Flow

```
┌──────────────┐      ┌──────────────────┐      ┌─────────────────┐
│ DecoderView  │─────▶│ DecoderViewModel │─────▶│  MorseDecoder   │
│  (SwiftUI)   │      │   (@Observable)  │      │  (AVAudioEngine)│
└──────┬───────┘      └────────┬─────────┘      └────────┬────────┘
       │                       │                          │
       ▼                       ▼                          ▼
 Record / Import       importAudioFile(url:)         Input-tap RMS
 WaveformView          decodeFromFile(url:)          Envelope detection
 Copy / Clear          Save Message to history       Threshold + segments
                       Inbox copy + security scope   MorseCodeMap.decode()
```

Two ways audio reaches the decoder:
- **Microphone**: `MorseDecoder.startRecording()` requests permission via `AVAudioApplication.requestRecordPermission`, then installs an input tap that streams RMS samples into `waveformData`.
- **File / share-sheet**: `MorseModemApp.onOpenURL` writes the URL into `sharedAudioURL`; `ContentView` switches to the Decoder tab; `DecoderViewModel.importAudioFile(url:)` copies `/Inbox/` files to `temporaryDirectory` (system may delete them) or calls `startAccessingSecurityScopedResource()` for files outside `/Inbox/`.

## Data Models (SwiftData)

```
┌────────────────────────────────────────────────────────┐
│                    SwiftData Store                     │
├────────────────────────┬───────────────────────────────┤
│      Message           │       AppSettings             │
├────────────────────────┼───────────────────────────────┤
│ • text: String         │ • toneFrequency: Double  Hz   │
│ • morseCode: String    │ • wordsPerMinute: Int         │
│ • timestamp: Date      │ • volume: Double  0…1         │
│ • isEncoded: Bool      │ • dotDuration / dashDuration  │
│                        │   intra/inter/wordGap         │
│                        │   (computed, PARIS timing)    │
└────────────────────────┴───────────────────────────────┘
```

`AppSettings.resolve(from:in:)` returns the existing row or inserts a default one — call it instead of constructing settings directly. Timing properties derive from `wordsPerMinute` via the standard `dotDuration = 60 / (50 × wpm)` PARIS formula; never hand-roll WPM math.

## Service Layer

```
┌─────────────────────────────────────────────────────────────┐
│                      Audio Services                         │
├─────────────────────────────┬───────────────────────────────┤
│      ToneGenerator          │       MorseDecoder            │
├─────────────────────────────┼───────────────────────────────┤
│ • Build single PCM buffer   │ • Record from microphone      │
│   for the whole morse string│ • Decode imported audio file  │
│ • 5 ms fade in/out per      │ • RMS envelope (512-sample    │
│   element (no clicks)       │   sliding window)             │
│ • Schedule on player node   │ • Adaptive threshold:         │
│ • Parallel CHHapticPattern  │   sortedEnv[3/4] × 0.5        │
│   (intensity 0.5 dot,       │ • Auto-detect dot duration =  │
│    0.8 dash)                │   min(toneDurations)          │
│ • Handles haptic engine     │ • segments→morse via 2u/5u    │
│   stoppedHandler /          │   thresholds                  │
│   resetHandler (background  │ • Imports `Accelerate` (room  │
│   restart)                  │   to vDSP-ify the RMS loop)   │
│ • Export to AAC .m4a        │                               │
└─────────────────────────────┴───────────────────────────────┘
```

## Utility Layer

```
┌─────────────────────────────────────────────────────────────┐
│                     MorseCodeMap                            │
├─────────────────────────────────────────────────────────────┤
│ • _charToMorse / _morseToChar are nonisolated(unsafe)       │
│   static dicts — readable off the main actor under          │
│   Swift 6 strict concurrency                                │
│ • encode(text):  words joined by DOUBLE space               │
│ • decode(morse): split on DOUBLE space → word boundary       │
│ • allCharacters() returns raw English category names        │
│   ("Letters", "Numbers", "Punctuation") that views          │
│   localize via LocalizedStringKey                            │
└─────────────────────────────────────────────────────────────┘
```

## Audio Processing Pipeline

### Tone Generation (Encoder)

```
text
  ↓ MorseCodeMap.encode()         → "... --- ..."
  ↓ For each element:
      • dot = dotDuration         (1 unit)
      • dash = dotDuration × 3    (3 units)
      • intra = 1u, inter = 3u, word = 7u
  ↓ Build samples (44.1 kHz):
      • sample = sin(2π·f·t) · volume
      • 5 ms linear fade in / fade out
  ↓ Single AVAudioPCMBuffer
  ↓ Schedule on AVAudioPlayerNode + start CHHapticPattern
  ↓ await scheduleBuffer completion
```

### Signal Decoding (Decoder)

```
mic / file → Float samples (44.1 kHz)
  ↓ computeEnvelope()
      • 512-sample window, half-window stride
      • RMS per window
  ↓ detectSegments()
      • threshold = sorted(envelope)[3/4] × 0.5
      • collapse runs into (isTone, duration)
  ↓ detectUnitDuration()
      • dot unit = min(tone durations)
  ↓ segmentsToMorse()
      • tone   < 2u → "."
      • tone  ≥ 2u → "-"
      • silence < 2u → intra-char (drop)
      • silence 2–5u → " " (inter-char)
      • silence > 5u → "  " (word gap)
  ↓ MorseCodeMap.decode()  →  text
```

## Concurrency

```
@MainActor      All view models, both audio services, and UI.
nonisolated     MorseCodeMap statics + encode/decode (pure).
async/await     playMorse, exportMorseAudio, decodeFromFile,
                requestMicrophonePermission, importAudioFile.
AVAudioEngine   Internal real-time thread; the input-tap closure
                hops back to @MainActor via Task before mutating state.
SwiftData       Single ModelContext from @Environment / init;
                view models receive ModelContext via init, not
                @Environment — keeps services testable.
```

Swift 6 strict concurrency is enabled. The two static morse dictionaries use `nonisolated(unsafe)` because they are immutable after initialization.

## Memory & Performance

- Audio buffers are temporary (released when the player node finishes).
- `recordedSamples` grows for the duration of a recording (Float per 1/44100 s).
- `waveformData` is capped at 1000 RMS values (older values are dropped via `replaceSubrange`).
- SwiftData's `@Query` provides lazy loading for History.
- Generated audio uses one buffer per playback (avoids per-sample scheduling).

## File Organization

All Swift sources live flat in `MorseModem/` (no nested groups on disk):

```
MorseModem/
├── MorseModemApp.swift          // @main, ModelContainer, .onOpenURL
├── ContentView.swift            // TabView root
├── SplashScreenView.swift       // 1.5 s launch overlay
│
├── AppSettings.swift            // @Model, PARIS timing
├── Message.swift                // @Model
├── MorseCodeMap.swift           // Pure encode/decode
│
├── ToneGenerator.swift          // @Observable, audio + haptics
├── MorseDecoder.swift           // @Observable, recording + decoding
│
├── EncoderViewModel.swift       // @MainActor @Observable
├── DecoderViewModel.swift       // @MainActor @Observable
│
├── EncoderView.swift / DecoderView.swift / ReferenceView.swift
├── HistoryView.swift / MessageDetailView.swift
├── SettingsView.swift / AboutView.swift
├── WaveformView.swift / ShareSheet.swift / ClipboardHelper.swift
│
├── Assets.xcassets/
├── Localizable.xcstrings        // All user-facing strings
├── Info.plist                   // CFBundleDocumentTypes for "Open in…"
└── Info.plist.example
```

## Key Design Patterns

1. **MVVM with `@Observable`** — view models own their service objects (`ToneGenerator`, `MorseDecoder`). Views observe; no Combine.
2. **Constructor-injected `ModelContext`** — view models receive `ModelContext` via init, not `@Environment`. Easier to test.
3. **Pure utility layer** — `MorseCodeMap` is value-only and `nonisolated`, callable from any actor.
4. **Single-buffer audio synthesis** — the entire morse string becomes one PCM buffer before playback. Haptics run on a parallel `CHHapticPattern` so audio + haptic timing stay aligned.

## Required Configuration

- `Info.plist` — `NSMicrophoneUsageDescription` for recording; `CFBundleDocumentTypes` registering `public.audio`, `public.mp3`, etc. (this is what enables "Open in MorseModem" from other apps).
- `Config.xcconfig` (gitignored) — `DEVELOPMENT_TEAM` for device builds. Copy from `Config.xcconfig.template`.
