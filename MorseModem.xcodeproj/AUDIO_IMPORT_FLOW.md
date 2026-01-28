# Audio Import Flow - Before and After Fix

## BEFORE (Broken) 🔴

```
User shares audio file from another app
           ↓
    onOpenURL() called
           ↓
    sharedAudioURL = url
           ↓
    ContentView receives URL
           ↓
    onChange(sharedAudioURL) fires
           ↓
    Switches to Decoder tab
           ↓
    DecoderView appears
           ↓
    onChange(sharedAudioURL) fires AGAIN
           ↓
    viewModel?.importAudioFile(url)
           ↓
    ❌ BUT viewModel is NIL!
           ↓
    Nothing happens
           ↓
    User sees empty screen
```

### Problem
The `viewModel` is only created in `onAppear`, which runs AFTER the `onChange` handler. By the time the viewModel exists, the URL has already been processed (and ignored).

---

## AFTER (Fixed) ✅

```
User shares audio file from another app
           ↓
    onOpenURL() called
           ↓
    📥 Logs URL details
           ↓
    Checks if file URL
           ↓
    Requests security-scoped access
           ↓
    sharedAudioURL = url
           ↓
    ContentView receives URL
           ↓
    onChange(sharedAudioURL) fires
           ↓
    Switches to Decoder tab
           ↓
    DecoderView appears
           ↓
    onChange(sharedAudioURL) fires
           ↓
    Is viewModel ready?
    ├─ NO  → Store URL in pendingURL
    │        Clear sharedAudioURL
    │              ↓
    │        onAppear() runs
    │              ↓
    │        Create viewModel
    │              ↓
    │        Check pendingURL
    │              ↓
    │        ✅ Process pendingURL
    │              ↓
    │        importAudioFile()
    │              ↓
    │        Show progress indicator
    │              ↓
    │        Decode audio
    │              ↓
    │        Display results
    │
    └─ YES → ✅ Process immediately
             importAudioFile()
                   ↓
             Show progress indicator
                   ↓
             Decode audio
                   ↓
             Display results
```

---

## Key Changes

### 1. Pending URL Queue
```swift
@State private var pendingURL: URL?
```
- Stores URLs that arrive before the viewModel is ready
- Processed in `onAppear` after viewModel initialization

### 2. Smart onChange Handler
```swift
.onChange(of: sharedAudioURL) { oldValue, newValue in
    if let url = newValue {
        if let viewModel = viewModel {
            // Ready: Process immediately
            Task {
                await viewModel.importAudioFile(url: url)
                sharedAudioURL = nil
            }
        } else {
            // Not ready: Store for later
            pendingURL = url
            sharedAudioURL = nil
        }
    }
}
```

### 3. Enhanced onAppear
```swift
.onAppear {
    if viewModel == nil {
        viewModel = DecoderViewModel(modelContext: modelContext)
        
        // Process any pending URL
        if let url = pendingURL {
            Task {
                await viewModel?.importAudioFile(url: url)
                pendingURL = nil
                sharedAudioURL = nil
            }
        }
    }
}
```

---

## Detailed Import Flow

### Step-by-Step with Logging

```
1. User shares audio from Voice Memos
   
2. MorseModemApp.onOpenURL() receives URL
   📥 Received URL: file:///.../Inbox/audio.m4a
   📥 URL scheme: Optional("file")
   📥 URL path: /.../Inbox/audio.m4a
   📥 Is file URL: true
   
3. Request security-scoped access
   ✅ Security-scoped resource access granted
   
4. Set sharedAudioURL
   sharedAudioURL = url
   
5. ContentView.onChange(sharedAudioURL)
   if newValue != nil {
       selectedTab = 1  // Switch to Decoder
   }
   
6. DecoderView appears
   - UI renders
   - Shows import button and instructions
   
7. DecoderView.onChange(sharedAudioURL)
   - Checks if viewModel exists
   - If NO: pendingURL = url
   
8. DecoderView.onAppear
   - Creates viewModel
   - Finds pendingURL is not nil
   - Calls importAudioFile()
   
9. DecoderViewModel.importAudioFile()
   🎵 Starting audio import from: file:///.../audio.m4a
   🎵 URL exists: true
   ✅ Security-scoped resource access granted
   
10. UI shows progress indicator
    "Importing and decoding audio..."
    
11. MorseDecoder.decodeFromFile()
    🎵 MorseDecoder: Opening audio file
    🎵 MorseDecoder: Audio file opened successfully
    🎵 Format: <AVAudioFormat 1 ch, 44100 Hz, Float32>
    🎵 Length: 220500 frames
    🎵 Duration: 5.0 seconds
    🎵 MorseDecoder: Audio data read into buffer
    🎵 MorseDecoder: Recorded 220500 samples
    
12. Process audio samples
    - Compute envelope
    - Detect segments
    - Auto-detect timing
    - Convert to morse
    - Decode to text
    
13. Results ready
    🎵 MorseDecoder: Decoding complete
    🎵 Decoded morse: ... --- ...
    🎵 Decoded text: SOS
    ✅ Decoded text: SOS
    ✅ Decoded morse: ... --- ...
    
14. Clean up
    🔒 Released security-scoped resource
    ✅ Import completed successfully
    
15. Update UI
    - Hide progress indicator
    - Show decoded morse code
    - Show decoded text
    - Enable copy button
    
16. Save to history
    - Create Message object
    - Insert into SwiftData
    - Save context
```

---

## File Locations During Import

### iOS File System

```
App Sandbox
├── Documents/
│   └── Inbox/                    ← Shared files land here
│       └── audio.m4a             ← Your shared file
│
├── Library/
│   └── Application Support/
│       └── default.store         ← SwiftData storage
│
└── tmp/
    └── exported_morse.m4a        ← Exported files (temporary)
```

### URL Types

1. **Shared from other apps:**
   ```
   file:///var/mobile/Containers/Data/Application/[UUID]/Documents/Inbox/audio.m4a
   ```
   - In app's Inbox folder
   - May not need security-scoped access
   - Auto-cleaned by iOS

2. **Picked via document picker:**
   ```
   file:///var/mobile/Media/Voice Memos/audio.m4a
   ```
   - Outside app sandbox
   - REQUIRES security-scoped access
   - Read-only access

---

## Security-Scoped Resources

### What are they?
iOS security feature that controls access to files outside your app's sandbox.

### When needed?
- ✅ Files from document picker
- ✅ Files from iCloud Drive
- ⚠️  Sometimes files from share sheet (depends on source)
- ❌ Files in your app's Documents/Inbox folder

### How to use?
```swift
// 1. Request access
if url.startAccessingSecurityScopedResource() {
    
    // 2. Use the file
    try await processFile(url)
    
    // 3. Release when done
    url.stopAccessingSecurityScopedResource()
}
```

### Our smart handling:
```swift
let needsSecurityScope = url.isFileURL && !url.path.contains("/Inbox/")

if needsSecurityScope {
    guard url.startAccessingSecurityScopedResource() else {
        throw NSError(...)
    }
}

defer {
    if needsSecurityScope {
        url.stopAccessingSecurityScopedResource()
    }
}
```

---

## Timeline Comparison

### BEFORE (Broken)
```
Time 0ms:   onOpenURL() → sharedAudioURL = url
Time 10ms:  ContentView.onChange() → selectedTab = 1
Time 20ms:  DecoderView.onChange() → viewModel?.import() [viewModel is nil!] ❌
Time 50ms:  DecoderView.onAppear() → viewModel created
Time 51ms:  [URL already processed and lost]
Result:     Nothing happens 🔴
```

### AFTER (Fixed)
```
Time 0ms:   onOpenURL() → sharedAudioURL = url
Time 10ms:  ContentView.onChange() → selectedTab = 1
Time 20ms:  DecoderView.onChange() → pendingURL = url ✅
Time 50ms:  DecoderView.onAppear() → viewModel created
Time 51ms:  Process pendingURL ✅
Time 52ms:  Import starts → Progress indicator shown
Time 100ms: Decoding...
Time 200ms: Results displayed ✅
Result:     Success! 🟢
```

---

## Error Handling Flow

```
importAudioFile(url)
        ↓
    Try to access file
        ↓
    ┌───┴────┐
    │        │
  Success  Failure
    │        │
    │        └→ Set importError
    │        └→ Show alert
    │        └→ isImporting = false
    │
    └→ Try to decode
            ↓
        ┌───┴────┐
        │        │
      Success  Failure
        │        │
        │        └→ Set importError
        │        └→ Show alert
        │        └→ isImporting = false
        │
        └→ Display results
        └→ Save to history
        └→ isImporting = false
```

---

## UI State Flow

```
Initial State
├── decodedText: ""
├── decodedMorse: ""
├── isImporting: false
└── importError: nil

        ↓ [User shares file]

Importing State
├── decodedText: ""
├── decodedMorse: ""
├── isImporting: true  ← Progress indicator shows
└── importError: nil

        ↓ [Decoding completes]

Success State
├── decodedText: "SOS"
├── decodedMorse: "... --- ..."
├── isImporting: false  ← Progress indicator hides
└── importError: nil

        OR

Error State
├── decodedText: ""
├── decodedMorse: ""
├── isImporting: false
└── importError: "Failed to..."  ← Error alert shows
```

---

## Testing Scenarios

### Scenario 1: Cold Start (App Not Running)
```
1. App is completely closed
2. User shares audio file
3. System launches app
4. onOpenURL() called during launch
5. App initializes all views
6. DecoderView appears
7. Pending URL is processed
✅ Expected: File imports successfully
```

### Scenario 2: Warm Start (App in Background)
```
1. App is suspended in background
2. User shares audio file
3. System brings app to foreground
4. onOpenURL() called
5. Views already exist
6. DecoderView already has viewModel
7. URL processed immediately
✅ Expected: File imports successfully
```

### Scenario 3: App Running (Different Tab)
```
1. App is in foreground on Encoder tab
2. User shares audio file
3. onOpenURL() called
4. ContentView switches to Decoder tab
5. If DecoderView just appeared: pending URL
6. If DecoderView already existed: immediate processing
✅ Expected: File imports successfully
```

### Scenario 4: App Running (Already on Decoder Tab)
```
1. App is on Decoder tab
2. viewModel already exists
3. User shares audio file
4. onOpenURL() called
5. URL processed immediately
✅ Expected: File imports successfully
```

---

## Summary

The fix ensures that **no matter when or how** a URL arrives, it will be properly processed:

1. ✅ **Early arrival** (before viewModel): Stored in pendingURL
2. ✅ **Late arrival** (after viewModel): Processed immediately
3. ✅ **Multiple imports**: Each handled in sequence
4. ✅ **Error cases**: Proper error messages shown
5. ✅ **User feedback**: Progress indicator during import
6. ✅ **Debug visibility**: Comprehensive logging

This makes the import feature **robust** and **reliable** across all use cases! 🎉
