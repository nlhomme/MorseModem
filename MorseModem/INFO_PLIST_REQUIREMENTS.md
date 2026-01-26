# Required Info.plist Entries

Add these entries to your Info.plist file for the app to function properly:

## Privacy - Microphone Usage Description

**Key:** `NSMicrophoneUsageDescription`
**Value:** "MorseModem needs access to your microphone to record and decode Morse code audio."

## Privacy - Files Access Description

While not always required, it's good practice to include:

**Key:** `NSDocumentsFolderUsageDescription`
**Value:** "MorseModem needs access to import audio files for Morse code decoding."

## Example Info.plist entries:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>MorseModem needs access to your microphone to record and decode Morse code audio.</string>
<key>NSDocumentsFolderUsageDescription</key>
<string>MorseModem needs access to import audio files for Morse code decoding.</string>
```

## Supported Audio Formats

The app supports importing these audio formats:
- M4A (AAC)
- WAV
- MP3
- AIFF
- CAF

These are automatically handled by the `fileImporter` with `.audio` content type.

## Background Modes

If you want to support background audio playback (optional):

**Capability:** Background Modes
**Mode:** Audio, AirPlay, and Picture in Picture

This is NOT required for the current implementation but could be added for continuous playback.
