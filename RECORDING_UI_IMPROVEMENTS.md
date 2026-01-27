# Recording UI Improvements

## Changes Made

### Problem
When the user tapped "Start Recording", there was no clear visual feedback that recording had started. The button appearance didn't change, and users couldn't see how long they had been recording.

### Solution
Added comprehensive visual feedback for the recording state:

#### 1. **Dynamic Button State** (`DecoderView.swift`)
- **Before Recording**: Blue button with microphone icon showing "Start Recording"
- **During Recording**: Red button with stop icon showing "Stop Recording" + live timer

#### 2. **Recording Duration Timer** (`DecoderViewModel.swift`)
- Added `recordingDuration: TimeInterval` property
- Created a `Timer` that updates every 0.1 seconds
- Timer starts when recording begins and stops when recording ends
- Displays as `MM:SS.T` format (minutes:seconds.tenths)

#### 3. **Visual Changes**

**Start Recording Button** (Not Recording):
```
┌─────────────────────────────────────┐
│  🎤  Start Recording                │  ← Blue background
└─────────────────────────────────────┘
```

**Stop Recording Button** (Recording):
```
┌─────────────────────────────────────┐
│  ⏹️  Stop Recording                  │  ← Red background
│        0:05.3                       │  ← Timer showing duration
└─────────────────────────────────────┘
```

### Technical Details

#### DecoderViewModel Changes
```swift
// Added properties
var recordingDuration: TimeInterval = 0
private var recordingStartTime: Date?
private var durationTimer: Timer?

// In startRecording()
recordingStartTime = Date()
recordingDuration = 0
durationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
    guard let self = self, let startTime = self.recordingStartTime else { return }
    Task { @MainActor in
        self.recordingDuration = Date().timeIntervalSince(startTime)
    }
}

// In stopRecording()
durationTimer?.invalidate()
durationTimer = nil
recordingStartTime = nil
recordingDuration = 0
```

#### DecoderView Changes
```swift
// Button now shows different content based on recording state
if viewModel?.morseDecoder.isRecording == true {
    // Recording state - show stop button with timer
    VStack(spacing: 8) {
        HStack(spacing: 12) {
            Image(systemName: "stop.circle.fill")
            Text("Stop Recording")
        }
        
        if let duration = viewModel?.recordingDuration {
            Text(formatDuration(duration))
                .font(.system(.body, design: .monospaced))
        }
    }
    .background(Color.red)  // Red background
} else {
    // Not recording - show start button
    HStack(spacing: 12) {
        Image(systemName: "mic.circle.fill")
        Text("Start Recording")
    }
    .background(Color.accentColor)  // Blue background
}

// Helper function
private func formatDuration(_ duration: TimeInterval) -> String {
    let minutes = Int(duration) / 60
    let seconds = Int(duration) % 60
    let milliseconds = Int((duration.truncatingRemainder(dividingBy: 1)) * 10)
    return String(format: "%d:%02d.%01d", minutes, seconds, milliseconds)
}
```

## User Experience

### Before
1. User taps "Start Recording"
2. ❌ No visible change to the button
3. ❌ No indication of recording status
4. ❌ No way to see recording duration
5. User confusion: "Did it start recording?"

### After
1. User taps "Start Recording"
2. ✅ Button immediately turns RED
3. ✅ Button text changes to "Stop Recording"
4. ✅ Button icon changes to stop icon
5. ✅ Timer appears and counts up (0:00.0, 0:00.1, 0:00.2...)
6. ✅ User can clearly see recording is active
7. ✅ User can see exactly how long they've been recording
8. User taps "Stop Recording"
9. ✅ Button returns to blue "Start Recording" state

## Visual Hierarchy

When recording is active, the UI now shows:

```
┌─────────────────────────────────────────────┐
│                                             │
│  🔴 RECORDING                               │  ← Banner (pulsing red dot)
│     Speak or play Morse code near device   │
│                                             │
│  ╔═══════════════════════════════╗        │
│  ║ Audio Level                   ║        │  ← Waveform visualization
│  ║ ▂▃▅▇▅▃▂▁▂▃▅▇▅▃▂              ║        │
│  ╚═══════════════════════════════╝        │
│                                             │
│  ┌───────────────────────────────┐        │
│  │  ⏹️  Stop Recording            │        │  ← RED button
│  │         0:05.3                │        │  ← Timer
│  └───────────────────────────────┘        │
│                                             │
│  ──────────── OR ────────────────         │
│                                             │
│  ┌───────────────────────────────┐        │
│  │  📁  Import Audio File         │        │  ← Disabled (grayed out)
│  └───────────────────────────────┘        │
│                                             │
└─────────────────────────────────────────────┘
```

## Benefits

1. **Clear Visual Feedback**: Users immediately see when recording starts
2. **Recording Duration**: Users know exactly how long they've been recording
3. **Professional Feel**: Red recording button is industry standard (like camera apps)
4. **Better Button Shadow**: Red button has stronger shadow when recording (more prominent)
5. **Prevents Confusion**: Users won't accidentally start multiple recordings
6. **Accessible**: Button label changes are picked up by VoiceOver

## Timer Format Examples

- `0:00.0` - Just started
- `0:05.3` - 5.3 seconds
- `0:15.7` - 15.7 seconds  
- `1:23.5` - 1 minute 23.5 seconds
- `5:00.0` - 5 minutes exactly

The timer updates 10 times per second (every 0.1s) for smooth, responsive feedback.

## Testing

### Test 1: Basic Recording
1. Open Decoder tab
2. Tap "Start Recording"
3. ✅ Button should immediately turn red
4. ✅ Text should change to "Stop Recording"
5. ✅ Timer should appear and start counting: 0:00.0, 0:00.1, 0:00.2...
6. Wait 5 seconds
7. ✅ Timer should show ~0:05.0
8. Tap "Stop Recording"
9. ✅ Button should return to blue "Start Recording"
10. ✅ Timer should disappear

### Test 2: Quick Start/Stop
1. Tap "Start Recording"
2. Immediately tap "Stop Recording" (within 1 second)
3. ✅ Should work without errors
4. ✅ Timer should show ~0:00.X

### Test 3: Long Recording
1. Tap "Start Recording"
2. Wait 90 seconds
3. ✅ Timer should show ~1:30.0
4. Tap "Stop Recording"
5. ✅ Should decode audio properly

### Test 4: Visual Feedback During Import
1. Start recording
2. While recording, the "Import Audio File" button should be disabled
3. ✅ Import button should be grayed out
4. Stop recording
5. ✅ Import button should become enabled again

## Code Quality

- Used `@MainActor` to ensure all timer updates happen on the main thread
- Used `weak self` in timer closure to prevent retain cycles
- Timer is properly invalidated in `deinit` and `stopRecording()`
- Duration is reset to 0 when recording stops
- Monospaced font for timer ensures no layout jumps during updates

## Future Improvements (Optional)

1. **Maximum Recording Duration**: Add a max time limit (e.g., 5 minutes) with warning
2. **Pause/Resume**: Allow pausing recording without losing progress
3. **Visual Timer Warning**: Change timer color when approaching max duration
4. **Haptic Feedback**: Add haptic feedback when recording starts/stops
5. **Animation**: Smooth transition animation between button states

## Related Files

- `DecoderView.swift` - UI changes for button and timer display
- `DecoderViewModel.swift` - Timer management and recording duration tracking
- `MorseDecoder.swift` - Recording state (`isRecording` property)

---

**Result**: Users now have clear, professional feedback when recording Morse code! 🎉
