# Audio Import Fix - Changes Made

## Problem
When sharing audio files from other apps to MorseModem, the app would open but nothing would happen - the audio file was not being imported or decoded.

## Root Cause
The issue was a **timing problem** during app launch:
1. When the app opens via share sheet, `onOpenURL` is called immediately
2. This sets `sharedAudioURL` in the app state
3. However, `DecoderView` hasn't appeared yet, so `viewModel` is `nil`
4. The `onChange(of: sharedAudioURL)` handler fires but tries to call `viewModel?.importAudioFile()` on a `nil` viewModel
5. Result: Nothing happens

## Solution
Implemented a **pending URL queue** system that:
1. Stores the URL temporarily if the viewModel isn't ready yet
2. Processes the URL as soon as the viewModel is initialized in `onAppear`
3. Handles both immediate processing (when viewModel exists) and deferred processing (when it doesn't)

## Files Modified

### 1. `DecoderView.swift`
**Changes:**
- Added `@State private var pendingURL: URL?` to store URLs that arrive before viewModel is ready
- Modified `onAppear` to process pending URLs after viewModel initialization
- Improved `onChange(of: sharedAudioURL)` to handle both immediate and deferred processing
- Added visual import status indicator with progress spinner

**Key Code:**
```swift
.onAppear {
    if viewModel == nil {
        viewModel = DecoderViewModel(modelContext: modelContext)
        
        // Process any pending URL that arrived before viewModel was ready
        if let url = pendingURL {
            Task {
                await viewModel?.importAudioFile(url: url)
                pendingURL = nil
                sharedAudioURL = nil
            }
        }
    }
}
.onChange(of: sharedAudioURL) { oldValue, newValue in
    if let url = newValue {
        if let viewModel = viewModel {
            // ViewModel is ready, process immediately
            Task {
                await viewModel.importAudioFile(url: url)
                sharedAudioURL = nil
            }
        } else {
            // ViewModel not ready yet, store for later
            pendingURL = url
            sharedAudioURL = nil
        }
    }
}
```

### 2. `DecoderViewModel.swift`
**Changes:**
- Enhanced `importAudioFile()` with better security-scoped resource handling
- Added special handling for files in the app's Inbox folder (don't need security scope)
- Added comprehensive debug logging to trace import process
- Improved error messages for users

**Key Improvements:**
```swift
// Smart detection of whether security-scoped access is needed
let needsSecurityScope = url.isFileURL && !url.path.contains("/Inbox/")

if needsSecurityScope {
    guard url.startAccessingSecurityScopedResource() else {
        throw NSError(...)
    }
}
```

### 3. `MorseModemApp.swift`
**Changes:**
- Enhanced `onOpenURL` with detailed logging
- Added better URL type detection (file URLs vs other URLs)
- Improved error handling for security-scoped resources
- Added fallback for non-file URLs

**Debug Output:**
```swift
print("📥 Received URL: \(url)")
print("📥 URL scheme: \(url.scheme ?? "none")")
print("📥 URL path: \(url.path)")
print("📥 Is file URL: \(url.isFileURL)")
```

### 4. `MorseDecoder.swift`
**Changes:**
- Added comprehensive logging to `decodeFromFile()` method
- Logs file format, duration, sample count
- Tracks decoding progress through each step
- Makes debugging much easier

## How to Test

### Test 1: Share from Voice Memos
1. Open **Voice Memos** app
2. Record a short audio (or use existing)
3. Tap the **Share** button
4. Select **MorseModem** from the share sheet
5. **Expected Result:**
   - App opens
   - Switches to Decoder tab
   - Shows "Importing and decoding audio..." indicator
   - Displays decoded results
   - Saves to history

### Test 2: Share from Files App
1. Open **Files** app
2. Find an audio file (M4A, WAV, MP3, etc.)
3. Long-press on the file
4. Tap **Share**
5. Select **MorseModem**
6. **Expected Result:** Same as Test 1

### Test 3: In-App Import
1. Open MorseModem
2. Go to **Decoder** tab
3. Tap **"Import Audio File"** button
4. Select an audio file from the picker
5. **Expected Result:**
   - Shows import indicator
   - Decodes the audio
   - Displays results

### Test 4: App Already Running
1. Open MorseModem
2. Navigate away from Decoder tab (go to Encoder or History)
3. Share an audio file from another app to MorseModem
4. **Expected Result:**
   - App comes to foreground
   - Automatically switches to Decoder tab
   - Imports and decodes the file

## Console Output to Expect

When sharing a file, you should see output like this in Xcode console:

```
📥 Received URL: file:///private/var/mobile/Containers/Data/Application/.../Documents/Inbox/audio.m4a
📥 URL scheme: Optional("file")
📥 URL path: /private/var/mobile/Containers/Data/Application/.../Documents/Inbox/audio.m4a
📥 Is file URL: true
✅ Security-scoped resource access granted

🎵 Starting audio import from: file:///.../audio.m4a
🎵 URL exists: true
✅ Security-scoped resource access granted

🎵 MorseDecoder: Opening audio file at file:///.../audio.m4a
🎵 MorseDecoder: Audio file opened successfully
🎵 Format: <AVAudioFormat ...>
🎵 Length: 220500 frames
🎵 Duration: 5.0 seconds
🎵 MorseDecoder: Audio data read into buffer
🎵 MorseDecoder: Recorded 220500 samples
🎵 MorseDecoder: Decoding complete
🎵 Decoded morse: ... --- ...
🎵 Decoded text: SOS
✅ Decoded text: SOS
✅ Decoded morse: ... --- ...
🔒 Released security-scoped resource
✅ Import completed successfully
```

## Troubleshooting

### If the app still doesn't appear in share sheet:
- Make sure `CFBundleDocumentTypes` is configured in Info.plist (see SHARE_CONFIGURATION.md)
- Clean build (Cmd+Shift+K)
- Rebuild the app
- Restart device/simulator

### If import fails with "Failed to access file":
- Check console logs for specific error
- Verify the file is a valid audio format
- Try importing from Files app instead

### If decoding produces no results:
- The audio may not contain detectable Morse code
- Check that the audio contains clear tone signals
- Verify the frequency is within 300-1500 Hz range
- Try with a test file generated by the Encoder

### If app crashes:
- Check console for specific error messages
- Verify the audio file isn't corrupted
- Try with different audio formats

## Benefits of This Fix

1. ✅ **Reliable Import**: Works regardless of app state (cold start, warm start, running)
2. ✅ **Better UX**: Shows progress indicator so users know something is happening
3. ✅ **Robust Error Handling**: Clear error messages when things go wrong
4. ✅ **Easy Debugging**: Comprehensive logging makes issues easy to diagnose
5. ✅ **Smart Resource Management**: Properly handles security-scoped resources
6. ✅ **Tab Switching**: Automatically switches to Decoder tab when file is shared

## Additional Notes

### Security-Scoped Resources
When files are shared from other apps:
- iOS copies them to your app's `Documents/Inbox/` folder
- Files in Inbox typically don't need security-scoped access
- Files accessed via document picker DO need security-scoped access
- We handle both cases automatically

### Clean-Up
iOS automatically cleans up files in the Inbox folder, so you don't need to worry about storage management for shared files.

### Future Improvements
Consider these enhancements:
- Add progress percentage for large files
- Show file name being imported
- Add option to save imported files permanently
- Support importing multiple files at once
- Add drag-and-drop support for iPad

## Debug Mode

The logging statements added are helpful for debugging. In production, you may want to:

1. Wrap them in `#if DEBUG` blocks:
```swift
#if DEBUG
print("🎵 Starting audio import...")
#endif
```

2. Or use `os.log` for better performance:
```swift
import os.log
let logger = Logger(subsystem: "com.nicolaslhomme.morsemodem", category: "import")
logger.debug("Starting audio import")
```

## Verification Checklist

Before considering this fix complete, verify:

- [ ] App appears in share sheet when sharing audio files
- [ ] App opens when audio file is shared
- [ ] Decoder tab is automatically selected
- [ ] Import progress indicator appears
- [ ] Audio file is decoded successfully
- [ ] Results are displayed in UI
- [ ] Message is saved to history
- [ ] No console errors appear
- [ ] Works with different audio formats (M4A, WAV, MP3)
- [ ] Works from different source apps (Voice Memos, Files, Safari)
- [ ] Works when app is not running
- [ ] Works when app is already running
- [ ] Error handling shows appropriate messages

## Success Criteria

The fix is successful when:
1. ✅ Sharing an audio file from any app opens MorseModem
2. ✅ The file is automatically imported and decoded
3. ✅ User sees clear progress indication
4. ✅ Results are displayed and saved to history
5. ✅ No crashes or silent failures occur
