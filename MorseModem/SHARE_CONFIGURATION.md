# Share Sheet Configuration Guide

To enable your app to receive audio files from other apps via the share sheet, you need to configure your Xcode project.

## Step 1: Configure Document Types in Xcode

1. Open your project in Xcode
2. Select the **MorseModem** target
3. Go to the **Info** tab
4. Add the following configurations:

### Option A: Using Xcode UI

#### Document Types Section:

Add a new **Document Type**:
- **Name**: Audio File
- **Types**: 
  - `public.audio`
  - `public.mp3`
  - `com.microsoft.waveform-audio`
  - `public.aifc-audio`
  - `public.aiff-audio`
  - `com.apple.m4a-audio`
- **Role**: Viewer
- **Handler Rank**: Alternate

#### Imported Type Identifiers (if needed):

Most audio types are already defined by the system, but you can import:
- `public.audio` (already defined by system)

### Option B: Using Info.plist XML

If you prefer to edit the Info.plist directly, add this:

```xml
<key>CFBundleDocumentTypes</key>
<array>
    <dict>
        <key>CFBundleTypeName</key>
        <string>Audio File</string>
        <key>LSItemContentTypes</key>
        <array>
            <string>public.audio</string>
            <string>public.mp3</string>
            <string>com.microsoft.waveform-audio</string>
            <string>public.aifc-audio</string>
            <string>public.aiff-audio</string>
            <string>com.apple.m4a-audio</string>
        </array>
        <key>CFBundleTypeRole</key>
        <string>Viewer</string>
        <key>LSHandlerRank</key>
        <string>Alternate</string>
    </dict>
</array>

<key>LSSupportsOpeningDocumentsInPlace</key>
<true/>

<key>UISupportsDocumentBrowser</key>
<true/>
```

## Step 2: Test the Configuration

After adding the configuration:

1. **Clean build** your project (Cmd+Shift+K)
2. **Build and run** (Cmd+R)
3. Test using one of these methods:

### Test with Voice Memos:
- Open Voice Memos
- Record or select a recording
- Tap Share button
- Your app should now appear in the share sheet

### Test with Files:
- Open Files app
- Navigate to an audio file
- Long-press and select Share
- Select MorseModem

### Test with Safari:
- Download an audio file
- Share it from downloads
- Select MorseModem

## Step 3: Verify the Implementation

Your current implementation in `MorseModemApp.swift` handles the URL:

```swift
.onOpenURL { url in
    // Handle incoming shared audio files
    if url.startAccessingSecurityScopedResource() {
        sharedAudioURL = url
    }
}
```

This will:
1. Receive the URL from the share sheet
2. Request security-scoped access
3. Pass it to `ContentView`
4. Switch to the Decoder tab
5. Load the audio file

## Troubleshooting

### App doesn't appear in share sheet:
- Verify `CFBundleDocumentTypes` is correctly configured
- Clean and rebuild the project
- Restart your device/simulator
- Check that you're sharing a compatible audio file type

### App opens but file doesn't load:
- Check `DecoderView` to ensure it handles `sharedAudioURL` properly
- Make sure `url.stopAccessingSecurityScopedResource()` is called when done
- Check console for security-scoped resource errors

### Permission issues:
- Ensure `NSMicrophoneUsageDescription` is in Info.plist
- Add `NSDocumentsFolderUsageDescription` if needed

## Alternative: Custom URL Scheme

If you also want to support custom URL schemes (e.g., `morsemodem://`), add:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>com.nicolaslhomme.morsemodem</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>morsemodem</string>
        </array>
    </dict>
</array>
```

Then you can test with URLs like: `morsemodem://import?file=...`

## Expected Behavior

When properly configured:
1. User shares audio file from another app
2. MorseModem appears in share sheet
3. User selects MorseModem
4. App opens (or comes to foreground)
5. Switches to Decoder tab
6. Audio file is loaded and ready to decode

## Security Notes

- Always call `startAccessingSecurityScopedResource()` before using shared files
- Call `stopAccessingSecurityScopedResource()` when done
- The app has temporary access to shared files
- Don't assume permanent access to shared file locations
