# Recording UI Not Showing - Troubleshooting Steps

## Issue
You mentioned not seeing the recording UI changes in the simulator.

## Possible Causes

### 1. **Xcode Didn't Rebuild** (Most Common)
Sometimes Xcode doesn't pick up file changes properly.

**Solution:**
```
1. Clean Build Folder: Product → Clean Build Folder (Cmd+Shift+K)
2. Quit Simulator completely
3. Quit Xcode
4. Reopen Xcode
5. Rebuild: Product → Build (Cmd+B)
6. Run again: Product → Run (Cmd+R)
```

### 2. **SwiftUI Preview Cache**
SwiftUI previews can cache old versions.

**Solution:**
```
1. In Xcode menu: Developer → Delete Derived Data
2. Restart Xcode
3. Rebuild
```

Manual cleanup:
```bash
# In Terminal:
rm -rf ~/Library/Developer/Xcode/DerivedData
rm -rf ~/Library/Caches/com.apple.dt.Xcode
```

### 3. **Microphone Permission Not Granted**
The simulator needs microphone permission.

**Solution:**
1. When you tap "Start Recording", you should see a permission alert
2. Tap "Allow"
3. If you already denied it:
   - Simulator → Settings → Privacy & Security → Microphone
   - Enable for MorseModem

### 4. **Debug Logging**
I've added debug output to help identify the issue.

**Check the Console for:**
```
🎤 Button tapped! Current isRecording: false
🎤 Starting recording...
🎤 DecoderViewModel: startRecording called
🎤 MorseDecoder: Permission granted
🎤 DecoderViewModel: Recording started, isRecording = true
```

**If you see:**
```
🎤 Button tapped! Current isRecording: false
🎤 Starting recording...
🎤 DecoderViewModel: startRecording called
🎤 DecoderViewModel: Recording failed - Microphone permission denied
```
→ Grant microphone permission

**If you see nothing in console:**
→ The button action isn't being called (rebuild needed)

### 5. **Debug Banner**
I've added a temporary debug banner that shows:
```
Debug: isRecording = TRUE/FALSE
```

This orange text should appear above the recording controls.

**If you don't see this:**
- The view isn't updating
- Clean and rebuild

**If you see "Debug: isRecording = FALSE" and it never changes to TRUE:**
- Recording isn't starting
- Check console for permission errors
- Check microphone is available in simulator

### 6. **Simulator Microphone**
The simulator needs your Mac's microphone.

**Check:**
1. System Settings → Privacy & Security → Microphone
2. Make sure "Xcode" or "Simulator" is enabled
3. Restart simulator after enabling

### 7. **File Changes Not Saved**
Make sure files are actually saved.

**Verify:**
1. Check if file tabs have dots (unsaved changes)
2. Save all: File → Save All (Cmd+Option+S)
3. Rebuild

## Step-by-Step Verification

### Step 1: Check Files Are Modified
Open these files and verify the changes are present:

**DecoderView.swift:**
Look for this code around line 40:
```swift
// Debug: Show recording state
if let isRecording = viewModel?.morseDecoder.isRecording {
    Text("Debug: isRecording = \(isRecording ? "TRUE" : "FALSE")")
```

Look for this code around line 45:
```swift
if viewModel?.morseDecoder.isRecording == true {
    VStack(spacing: 16) {
        // Prominent Recording Indicator
        HStack(spacing: 12) {
            ZStack {
                // Pulsing outer ring
                Circle()
```

**If you DON'T see this code:**
- The file didn't save properly
- Re-apply the changes

### Step 2: Clean Build
```
1. Xcode menu: Product → Clean Build Folder (Cmd+Shift+K)
2. Wait for "Clean Finished"
3. Xcode menu: Product → Build (Cmd+B)
4. Wait for "Build Succeeded"
```

### Step 3: Reset Simulator
```
1. Simulator menu: Device → Erase All Content and Settings
2. Wait for reset
3. Run app again from Xcode
```

### Step 4: Test Recording
```
1. Open the app
2. Go to Decoder tab
3. Look for orange debug banner
4. Tap "Start Recording"
5. Check console for debug messages
6. Look for recording banner
```

### Step 5: Expected Results

**Before tapping Start Recording:**
```
┌─────────────────────────────────────┐
│ Debug: isRecording = FALSE          │ ← Orange debug text
│                                     │
│ [Start Recording Button - Blue]     │
│ [Import Audio File - Green]         │
└─────────────────────────────────────┘
```

**After tapping Start Recording:**
```
┌─────────────────────────────────────┐
│ Debug: isRecording = TRUE           │ ← Orange debug text
│                                     │
│ ╔═══════════════════════════════╗   │
│ ║ ⦿ RECORDING                   ║   │ ← Red banner
│ ║   Speak or play Morse code... ║   │
│ ╚═══════════════════════════════╝   │
│                                     │
│ ┌───────────────────────────────┐   │
│ │ Listening for audio...        │   │ ← Placeholder
│ └───────────────────────────────┘   │
│                                     │
│ [Stop Recording Button - Red]       │ ← Changed to red
│                                     │
│ ────────── OR ──────────            │ ← Separator
│                                     │
│ [Import - Dimmed]                   │ ← 50% opacity
└─────────────────────────────────────┘
```

## Console Output to Look For

### Successful Recording Start:
```
🎤 Button tapped! Current isRecording: false
🎤 Starting recording...
🎤 DecoderViewModel: startRecording called
🎵 MorseDecoder: Opening audio file at ...
🎤 DecoderViewModel: Recording started, isRecording = true
```

### Permission Denied:
```
🎤 Button tapped! Current isRecording: false
🎤 Starting recording...
🎤 DecoderViewModel: startRecording called
🎤 DecoderViewModel: Recording failed - Microphone permission denied
```

### Nothing Happens (No Console Output):
This means:
- Button action isn't connected
- File didn't rebuild
- **Solution: Clean and rebuild**

## Quick Diagnostic

Run this checklist:

```
[ ] Files contain the new code (check for "Debug: isRecording")
[ ] Files are saved (no dots on tabs)
[ ] Clean build performed
[ ] App rebuilt successfully
[ ] Simulator restarted
[ ] Orange debug banner appears in app
[ ] Microphone permission granted
[ ] Console shows debug messages when button tapped
[ ] Recording banner appears when isRecording = TRUE
```

## Still Not Working?

### Try This:
1. **Create a new test:**
   ```swift
   // Add this at the top of DecoderView body:
   Text("TEST: View is loaded")
       .foregroundColor(.green)
   ```

2. **If you don't see "TEST: View is loaded":**
   - The file isn't being used
   - Wrong target selected
   - Check scheme settings

3. **If you see "TEST: View is loaded" but no debug banner:**
   - viewModel is nil
   - Check onAppear is called

4. **Manual verification in Xcode:**
   - Set a breakpoint on the button action
   - Tap button
   - If breakpoint doesn't hit → rebuild issue
   - If breakpoint hits → step through code

## Alternative: Verify Code is Present

In Xcode:
1. Press Cmd+Shift+O (Open Quickly)
2. Type "DecoderView"
3. Press Enter
4. Press Cmd+F (Find)
5. Search for "Debug: isRecording"
6. If found → Code is there
7. If not found → File wasn't modified

## Nuclear Option

If nothing works:

```bash
# Close Xcode completely
# In Terminal:
cd ~/Library/Developer/Xcode/
rm -rf DerivedData
rm -rf iOS\ DeviceSupport
cd ~/Library/Caches/
rm -rf com.apple.dt.Xcode

# Restart Mac
# Open Xcode
# Open project
# Build
```

## Expected Behavior

**The changes ARE in the code.** If you're not seeing them:
1. ✅ The code is definitely there
2. ❌ Xcode hasn't rebuilt with the new code
3. **Solution: Clean build and rebuild**

## Debug Banner

The orange "Debug: isRecording" banner will tell you:
- **If it shows FALSE → TRUE**: Recording is working, UI should update
- **If it stays FALSE**: Recording isn't starting (permission issue)
- **If it's not visible**: View isn't updating (rebuild issue)

## Summary

Most likely cause: **Xcode build cache**

Solution:
1. Clean Build Folder (Cmd+Shift+K)
2. Quit Simulator
3. Rebuild (Cmd+B)
4. Run (Cmd+R)
5. Look for orange debug banner
6. Check console output

The code IS there - you just need to get Xcode to rebuild properly!
