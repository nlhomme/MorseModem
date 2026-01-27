# Share Sheet Import Troubleshooting Guide

## Changes Made to Fix Security-Scoped Resource Error

### Problem
When sharing audio files to the app via share sheet, users got the error: "Failed to access security-scoped resource"

### Root Cause
The app was trying to call `startAccessingSecurityScopedResource()` twice:
1. Once in `MorseModemApp.onOpenURL()`
2. Again in `DecoderViewModel.importAudioFile()`

**You can only call this method once per URL**, and calling it twice causes it to fail.

### Solution Applied

#### 1. Removed Security-Scoped Access from MorseModemApp
**Before:**
```swift
.onOpenURL { url in
    if url.startAccessingSecurityScopedResource() {
        sharedAudioURL = url
    }
}
```

**After:**
```swift
.onOpenURL { url in
    // Just pass the URL through
    // Let DecoderViewModel handle security-scoped access
    sharedAudioURL = url
}
```

#### 2. Improved Security-Scoped Access Logic in DecoderViewModel
The new logic:
- ✅ Files in `/Inbox/` → Copy to temp location, NO security-scoped access needed
- ✅ Files from document picker → Request security-scoped access
- ✅ Only call `startAccessingSecurityScopedResource()` once
- ✅ Always release with `stopAccessingSecurityScopedResource()` in cleanup

#### 3. Added Comprehensive Logging
Now you can see exactly what's happening:
```
🎵 ===== IMPORT AUDIO FILE =====
🎵 URL: file:///path/to/file.m4a
🎵 URL.path: /path/to/file.m4a
🎵 URL.isFileURL: true
🎵 File exists at path: true
📁 File is in Inbox, creating working copy...
✅ Created working copy at: /tmp/file.m4a
ℹ️ Skipping security-scoped access (not needed)
🎵 Decoding file from: /tmp/file.m4a
✅ Import completed successfully
```

---

## How to Test

### Test 1: Share from Voice Memos
1. Open **Console.app** or **Xcode Console**
2. Filter for your app or look for emoji 🎵 📥 logs
3. Open **Voice Memos**
4. Share an audio file to MorseModem
5. **Check the console output**

### Expected Console Output (Success)
```
📥 Received URL: file:///.../Documents/Inbox/audio.m4a
✅ URL passed to ContentView
🎵 ===== IMPORT AUDIO FILE =====
🎵 URL: file:///.../Documents/Inbox/audio.m4a
🎵 URL.path: /.../Documents/Inbox/audio.m4a
🎵 URL.isFileURL: true
🎵 File exists at path: true
🎵 File size: 123456
📁 File is in Inbox, creating working copy...
✅ Created working copy at: /tmp/audio.m4a
ℹ️ Skipping security-scoped access (not needed)
🎵 Decoding file from: /tmp/audio.m4a
🎵 MorseDecoder: Opening audio file at /tmp/audio.m4a
🎵 MorseDecoder: Audio file opened successfully
🎵 Format: <AVAudioFormat 1 ch, 44100 Hz, Float32>
🎵 Length: 220500 frames
🎵 Duration: 5.0 seconds
🎵 MorseDecoder: Recorded 220500 samples
🎵 MorseDecoder: Decoding complete
🎵 Decoded morse: ... --- ...
🎵 Decoded text: SOS
✅ Decoded text: 'SOS'
✅ Decoded morse: '... --- ...'
✅ Saved to history
✅ Import completed successfully
🗑️ Cleaned up temporary file
```

### Expected Console Output (If File Has No Morse Code)
```
[... same as above until ...]
🎵 MorseDecoder: Decoding complete
🎵 Decoded morse: 
🎵 Decoded text: 
✅ Decoded text: ''
✅ Decoded morse: ''
⚠️ No text decoded, not saving to history
✅ Import completed successfully
```

---

## Common Issues and Solutions

### Issue 1: "Failed to access security-scoped resource"
**Symptoms:**
- Error appears immediately when sharing
- Console shows: `❌ Failed to access security-scoped resource`

**Solution:**
✅ **FIXED** - We removed the duplicate security-scoped access call

**How it's fixed:**
- Only `DecoderViewModel` calls `startAccessingSecurityScopedResource()`
- Only called once per URL
- Only called for files that need it (not Inbox files)

### Issue 2: File not found
**Symptoms:**
- Console shows: `🎵 File exists at path: false`
- Error: "Failed to create buffer" or "No such file"

**Possible Causes:**
1. File path has special characters or encoding issues
2. File was already cleaned up by iOS
3. URL format is incorrect

**Debugging:**
Check the console for:
```
🎵 URL.path: /path/to/file
🎵 File exists at path: false
🎵 Alternate path: /different/path/to/file
🎵 File exists at alternate path: true
```

**Solution:**
Our code now:
- Copies Inbox files to a temporary location immediately
- Checks both regular and percent-encoded paths
- Shows detailed file information

### Issue 3: File opens but no Morse code detected
**Symptoms:**
- Import completes successfully
- But decoded text and morse are empty
- Console shows: `⚠️ No text decoded`

**Causes:**
- The audio file doesn't contain Morse code
- The Morse code frequency is outside 300-1500 Hz
- The signal is too quiet or noisy

**Testing:**
1. Use the **Encoder** tab to generate a test file
2. Share that file to test the import
3. This confirms the import mechanism works

**Example:**
```
Encoder tab:
1. Type "SOS"
2. Tap "Export Audio"
3. Save to Files
4. Share that file to MorseModem
5. Should decode as "SOS"
```

### Issue 4: App doesn't appear in share sheet
**Symptoms:**
- When trying to share audio, MorseModem isn't listed

**Solution:**
1. Check `Info.plist` has `CFBundleDocumentTypes` configured
2. Clean build folder (Cmd+Shift+K)
3. Delete app from device
4. Rebuild and reinstall
5. Restart device if needed

**Verify Info.plist:**
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
```

### Issue 5: Permission denied errors
**Symptoms:**
- Console shows permission-related errors
- "Operation not permitted"

**Solution:**
1. Check `Info.plist` has microphone permission (for recording, not import)
2. For file access, iOS should handle this automatically
3. Try resetting privacy settings: Settings → General → Reset → Reset Location & Privacy

---

## File System Behavior

### Where do shared files go?

When you share a file to your app:

1. **iOS copies** the file to your app's container
2. Location: `/var/mobile/Containers/Data/Application/[UUID]/Documents/Inbox/`
3. The file is **temporary** - iOS may delete it
4. Your app **DOES NOT** need security-scoped access to Inbox files

### Our strategy:
```swift
if url.path.contains("/Inbox/") {
    // Copy to our own temp location
    let tempURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent(filename)
    try FileManager.default.copyItem(at: url, to: tempURL)
    // Use tempURL for processing
    // Clean up when done
}
```

### Why copy the file?
1. ✅ iOS might delete the Inbox file while we're using it
2. ✅ We control the lifetime of our temp copy
3. ✅ We can process it without worrying about external cleanup
4. ✅ We clean up ourselves when done

---

## Understanding Security-Scoped Resources

### What are they?
A security mechanism that controls file access outside your app's container.

### When are they needed?

| Source | Needs Security-Scoped Access? |
|--------|-------------------------------|
| Share sheet → Inbox | ❌ NO |
| Document picker | ✅ YES |
| iCloud Drive picker | ✅ YES |
| Files from other apps' containers | ✅ YES |
| Your app's Documents | ❌ NO |
| Your app's temporary directory | ❌ NO |

### How to use them correctly:

```swift
// 1. Check if needed
let needsAccess = !url.path.contains("/Inbox/") && url.isFileURL

// 2. Request access (only if needed)
var didStart = false
if needsAccess {
    didStart = url.startAccessingSecurityScopedResource()
}

// 3. Use the file
try processFile(url)

// 4. ALWAYS release (if you started access)
if didStart {
    url.stopAccessingSecurityScopedResource()
}
```

### Common mistakes:

❌ **Calling it twice on the same URL**
```swift
// DON'T DO THIS:
url.startAccessingSecurityScopedResource()  // First call
// ... pass url around ...
url.startAccessingSecurityScopedResource()  // Second call - FAILS!
```

✅ **Call it once**
```swift
// DO THIS:
if url.startAccessingSecurityScopedResource() {
    defer { url.stopAccessingSecurityScopedResource() }
    // Use the URL
}
```

❌ **Calling it on Inbox files**
```swift
// DON'T NEED THIS:
if url.path.contains("/Inbox/") {
    url.startAccessingSecurityScopedResource()  // Not needed!
}
```

✅ **Skip it for Inbox files**
```swift
// DO THIS:
if !url.path.contains("/Inbox/") {
    url.startAccessingSecurityScopedResource()
}
```

---

## Debugging Checklist

When import fails, check these in order:

### 1. Is the app receiving the URL?
Look for:
```
📥 Received URL: file://...
```
- ✅ If you see this → URL is being received
- ❌ If you don't → Check Info.plist configuration

### 2. Is the URL being passed to DecoderView?
Look for:
```
✅ URL passed to ContentView
🎵 ===== IMPORT AUDIO FILE =====
```
- ✅ If you see this → URL routing works
- ❌ If you don't → Check `onChange` handlers in ContentView/DecoderView

### 3. Does the file exist?
Look for:
```
🎵 File exists at path: true
```
- ✅ If true → File is accessible
- ❌ If false → File path issue or already deleted

### 4. Is the file being copied?
Look for:
```
📁 File is in Inbox, creating working copy...
✅ Created working copy at: /tmp/...
```
- ✅ If you see this → File copy succeeded
- ❌ If error → Check disk space or file permissions

### 5. Is the file being decoded?
Look for:
```
🎵 MorseDecoder: Opening audio file at ...
🎵 MorseDecoder: Audio file opened successfully
```
- ✅ If you see this → Audio file is valid
- ❌ If error → File might be corrupted or unsupported format

### 6. Did decoding produce results?
Look for:
```
✅ Decoded text: 'SOS'
✅ Decoded morse: '... --- ...'
```
- ✅ If you see results → SUCCESS!
- ⚠️ If empty → Audio doesn't contain detectable Morse code

---

## Testing Strategy

### 1. Generate Test File
```
1. Open Encoder tab
2. Type "TEST" or "SOS"
3. Tap "Export Audio"
4. Save to Files app
```

### 2. Test Share from Files
```
1. Open Files app
2. Find the exported file
3. Long-press → Share → MorseModem
4. Check console for logs
5. Verify it decodes correctly
```

### 3. Test Share from Voice Memos
```
1. Open Voice Memos
2. Play a Morse code recording
3. Tap Share → MorseModem
4. Check console for logs
```

### 4. Test Document Picker
```
1. Open MorseModem → Decoder tab
2. Tap "Import Audio File"
3. Select the test file
4. Should work perfectly
```

---

## Expected Behavior Matrix

| Scenario | Should Work? | Security-Scoped Access? |
|----------|--------------|------------------------|
| Share from Voice Memos | ✅ YES | ❌ NO (Inbox) |
| Share from Files app | ✅ YES | ❌ NO (Inbox) |
| Share from Safari download | ✅ YES | ❌ NO (Inbox) |
| Import via document picker | ✅ YES | ✅ YES |
| Import from iCloud Drive | ✅ YES | ✅ YES |
| Drag & drop (iPad) | ⚠️ Not implemented yet | - |

---

## Success Indicators

Your fix is working if you see:

1. ✅ No "Failed to access security-scoped resource" error
2. ✅ Console shows complete import flow
3. ✅ File is copied to temp location
4. ✅ Morse code is decoded
5. ✅ Results are displayed in UI
6. ✅ Message saved to history
7. ✅ No crashes or hangs

---

## Quick Test Script

Run through this sequence:

```
1. Open Xcode Console
2. Build and run app
3. Tap Encoder tab
4. Type "SOS"
5. Tap "Export Audio"
6. Save to Files
7. Open Files app
8. Share that file to MorseModem
9. Watch console output
10. Verify "SOS" appears in Decoder

Expected result: Full success with complete logs
```

---

## If All Else Fails

### Nuclear Option: Clean Everything
```bash
# In Xcode:
1. Product → Clean Build Folder (Cmd+Shift+K)
2. Delete app from device/simulator
3. Delete derived data:
   rm -rf ~/Library/Developer/Xcode/DerivedData/*
4. Restart Xcode
5. Rebuild and run
```

### Check Device State
```
1. Settings → Privacy & Security → Files and Folders
   → Check if MorseModem has access
2. Settings → General → iPhone Storage
   → Check available space (need at least 100MB)
3. Restart device
```

### Verify Code Changes
Ensure all three files have the latest changes:
- ✅ MorseModemApp.swift - NO security-scoped access in onOpenURL
- ✅ DecoderViewModel.swift - Smart security-scoped access with Inbox detection
- ✅ DecoderView.swift - Pending URL queue system

---

## Contact/Report

If you still have issues after trying everything:

1. **Capture complete console output** from app launch to error
2. **Note the source app** you're sharing from
3. **Note the file format** (M4A, WAV, MP3, etc.)
4. **Include any error messages** shown in UI
5. **Check for patterns** - does it fail with all files or just some?

This comprehensive logging should help identify any remaining issues!
