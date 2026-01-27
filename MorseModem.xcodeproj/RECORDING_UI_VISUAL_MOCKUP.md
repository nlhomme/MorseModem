# Recording UI - Visual Mockup

## Complete Screen States

### State 1: Default (Not Recording)

```
┌─────────────────────────────────────────────┐
│              ← Decoder                      │
├─────────────────────────────────────────────┤
│                                             │
│  ┌─────────────────────────────────────────┐│
│  │                                          ││
│  │   🎤  Start Recording                    ││ ← Blue button
│  │                                          ││   (Accent color)
│  │                                          ││
│  └─────────────────────────────────────────┘│
│                                             │
│  ┌─────────────────────────────────────────┐│
│  │                                          ││
│  │   📁  Import Audio File                  ││ ← Green button
│  │                                          ││   (Full opacity)
│  │                                          ││
│  └─────────────────────────────────────────┘│
│                                             │
│            🎙                               │
│                                             │
│      Decode Morse Code                      │
│                                             │
│   Record audio with your microphone         │
│   or import an audio file containing        │
│   Morse code.                               │
│                                             │
│                                             │
└─────────────────────────────────────────────┘
```

---

### State 2: Recording Started (Waiting for Audio)

```
┌─────────────────────────────────────────────┐
│              ← Decoder                      │
├─────────────────────────────────────────────┤
│                                             │
│  ╔═══════════════════════════════════════╗ │
│  ║                                       ║ │
│  ║  ⦿  RECORDING                         ║ │ ← Bold text
│  ║                                       ║ │   Red dot pulsing
│  ║     Speak or play Morse code          ║ │   Red background
│  ║     near your device                  ║ │   Red border
│  ║                                       ║ │
│  ╚═══════════════════════════════════════╝ │
│                                             │
│  ┌───────────────────────────────────────┐ │
│  │                                       │ │
│  │         ⚪                            │ │ ← Spinner
│  │  Listening for audio...               │ │   Gray text
│  │                                       │ │
│  └───────────────────────────────────────┘ │
│                                             │
│  ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓ │
│  ┃                                       ┃ │
│  ┃   🛑  Stop Recording                  ┃ │ ← Red button
│  ┃                                       ┃ │   Large & bold
│  ┃                                       ┃ │   Shadow effect
│  ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛ │
│                                             │
│  ────────────── OR ────────────────        │ ← Separator
│                                             │
│  ┌───────────────────────────────────────┐ │
│  │   📁  Import Audio File               │ │ ← Dimmed 50%
│  └───────────────────────────────────────┘ │   (Disabled)
│                                             │
└─────────────────────────────────────────────┘
```

---

### State 3: Recording Active (With Audio)

```
┌─────────────────────────────────────────────┐
│              ← Decoder                      │
├─────────────────────────────────────────────┤
│                                             │
│  ╔═══════════════════════════════════════╗ │
│  ║                                       ║ │
│  ║  ⦿  RECORDING                         ║ │ ← Pulsing
│  ║                                       ║ │   animation
│  ║     Speak or play Morse code          ║ │
│  ║     near your device                  ║ │
│  ║                                       ║ │
│  ╚═══════════════════════════════════════╝ │
│                                             │
│  ┌───────────────────────────────────────┐ │
│  │ Audio Level                           │ │ ← Label
│  │                                       │ │
│  │ ▂▅█▇▆▄▃▂▁▃▄▆█▇▅▃▂▁▂▄▅▇█▆▄▃▁       │ │ ← Live waveform
│  │                                       │ │   Updates real-time
│  │                                       │ │
│  └───────────────────────────────────────┘ │
│                                             │
│  ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓ │
│  ┃   🛑  Stop Recording                  ┃ │
│  ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛ │
│                                             │
│  ────────────── OR ────────────────        │
│                                             │
│  ┌───────────────────────────────────────┐ │
│  │   📁  Import Audio File               │ │ ← Still dimmed
│  └───────────────────────────────────────┘ │
│                                             │
└─────────────────────────────────────────────┘
```

---

### State 4: Recording Stopped (With Results)

```
┌─────────────────────────────────────────────┐
│              ← Decoder                      │
├─────────────────────────────────────────────┤
│                                             │
│  ┌─────────────────────────────────────────┐│
│  │   🎤  Start Recording                    ││ ← Back to blue
│  └─────────────────────────────────────────┘│
│                                             │
│  ┌─────────────────────────────────────────┐│
│  │   📁  Import Audio File                  ││ ← Re-enabled
│  └─────────────────────────────────────────┘│
│                                             │
│  ┌───────────────────────────────────────┐ │
│  │ Decoded Morse Code                    │ │
│  │                                       │ │
│  │  ... --- ...                          │ │
│  │                                       │ │
│  └───────────────────────────────────────┘ │
│                                             │
│  ┌───────────────────────────────────────┐ │
│  │ Decoded Text              [Copy]      │ │
│  │                                       │ │
│  │  SOS                                  │ │
│  │                                       │ │
│  └───────────────────────────────────────┘ │
│                                             │
│  ┌───────────────────────────────────────┐ │
│  │   ✕  Clear Results                    │ │
│  └───────────────────────────────────────┘ │
│                                             │
└─────────────────────────────────────────────┘
```

---

## Component Closeups

### Recording Banner (Detailed)

```
╔═══════════════════════════════════════════════╗
║                                               ║
║  ⦿                                            ║ ← Red dot (16pt)
║  ◯                                            ║ ← Pulsing ring (24pt)
║                                               ║
║     RECORDING                                 ║ ← .headline, .bold
║                                               ║
║     Speak or play Morse code near your device ║ ← .caption, .secondary
║                                               ║
╚═══════════════════════════════════════════════╝
                                               
Colors:
- Fill: Color.red.opacity(0.15)
- Border: Color.red.opacity(0.5), 2pt width
- Text: .primary (white in dark mode, black in light)
- Subtitle: .secondary
- Dot: Color.red
- Ring: Color.red.opacity(0.3)
```

---

### Audio Level Display (With Waveform)

```
┌─────────────────────────────────────────────┐
│ Audio Level                                 │ ← .caption, .secondary
│                                             │
│                                             │
│ ▂▅█▇▆▄▃▂▁▃▄▆█▇▅▃▂▁▂▄▅▇█▆▄▃▁▂▃▅▆▇█▆▅▃▂    │ ← Canvas bars
│                                             │    Height: 80pt
│                                             │    Accent color
│                                             │
└─────────────────────────────────────────────┘

Background: .secondarySystemBackground
Padding: 16pt all sides
Corner radius: 12pt
```

---

### Audio Level Display (Placeholder)

```
┌─────────────────────────────────────────────┐
│                                             │
│              ⚪                             │ ← ProgressView
│                                             │    .tint(.red)
│       Listening for audio...                │ ← .caption, .secondary
│                                             │
└─────────────────────────────────────────────┘

Height: 60pt (fixed)
Background: .secondarySystemBackground
Corner radius: 12pt
```

---

### Stop Recording Button

```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃                                             ┃
┃    🛑        Stop Recording                 ┃
┃   (.title2)   (.semibold)                   ┃
┃                                             ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

Colors:
- Background: Color.red
- Foreground: .white
- Shadow: Color.red.opacity(0.3), radius 8, y: 4

Padding: 16pt vertical
Corner radius: 12pt
Width: .infinity (full width minus margins)
```

---

### Start Recording Button

```
┌─────────────────────────────────────────────┐
│                                             │
│    🎤        Start Recording                │
│   (.title2)   (.semibold)                   │
│                                             │
└─────────────────────────────────────────────┘

Colors:
- Background: Color.accentColor (blue)
- Foreground: .white
- Shadow: Color.accentColor.opacity(0.3), radius 8, y: 4

Padding: 16pt vertical
Corner radius: 12pt
```

---

### Import Button (Enabled)

```
┌─────────────────────────────────────────────┐
│                                             │
│    📁        Import Audio File              │
│  (.title3)    (.medium)                     │
│                                             │
└─────────────────────────────────────────────┘

Colors:
- Background: Color.green
- Foreground: .white
- Opacity: 1.0

Padding: 14pt vertical
Corner radius: 12pt
```

---

### Import Button (Disabled - During Recording)

```
┌─────────────────────────────────────────────┐
│                                             │
│    📁        Import Audio File              │ ← 50% opacity
│                                             │
└─────────────────────────────────────────────┘

Colors:
- Background: Color.green
- Foreground: .white
- Opacity: 0.5

Disabled: true
User interaction: None
```

---

### OR Separator

```
─────────────────  OR  ─────────────────

Colors:
- Lines: Color.gray.opacity(0.3)
- Text: .secondary, .caption
- Line height: 1pt
- Vertical padding: 8pt
```

---

## Animation Sequences

### Pulsing Recording Indicator

```
Frame 1 (0.0s):
⦿ (size: 1.0x)
○ (size: 1.0x, opacity: 0.3)

Frame 2 (0.2s):
⦿ (size: 1.1x)
◯ (size: 1.3x, opacity: 0.2)

Frame 3 (0.4s):
⦿ (size: 1.0x)
◯ (size: 1.5x, opacity: 0.1)

Frame 4 (0.6s):
⦿ (size: 0.9x)
○ (size: 1.3x, opacity: 0.2)

Frame 5 (0.8s):
⦿ (size: 1.0x)
○ (size: 1.0x, opacity: 0.3)

Then repeats...

Animation:
- Duration: 0.8 seconds
- Curve: .easeInOut
- Repeats: Forever
- Autoreverses: true
```

---

### Waveform Real-Time Update

```
Time 0.0s: ▂▃▄▅▆▇█▇▆▅▄▃▂▁
Time 0.1s:  ▂▃▄▅▆▇█▇▆▅▄▃▂  ← New bar added
Time 0.2s:   ▂▃▄▅▆▇█▇▆▅▄▃▂▁ ← Shifts left
Time 0.3s:    ▂▃▄▅▆▇█▇▆▅▄▃▂
...continues...

Max bars: 1000
Update rate: ~10Hz (every 100ms)
When full: Remove first, add last (circular buffer)
```

---

## Color Palette

### Light Mode

```
Recording Banner:
- Background: rgba(255, 59, 48, 0.15)  // 15% red
- Border: rgba(255, 59, 48, 0.5)       // 50% red
- Dot: rgb(255, 59, 48)                // 100% red
- Ring: rgba(255, 59, 48, 0.3)         // 30% red
- Text: rgb(0, 0, 0)                   // Black
- Subtitle: rgb(142, 142, 147)         // Gray

Stop Button:
- Background: rgb(255, 59, 48)         // Red
- Text: rgb(255, 255, 255)             // White
- Shadow: rgba(255, 59, 48, 0.3)       // 30% red

Start Button:
- Background: rgb(0, 122, 255)         // Blue (accent)
- Text: rgb(255, 255, 255)             // White
- Shadow: rgba(0, 122, 255, 0.3)       // 30% blue

Import Button:
- Background: rgb(52, 199, 89)         // Green
- Text: rgb(255, 255, 255)             // White
- Opacity (disabled): 0.5              // 50%

Audio Level:
- Background: rgb(242, 242, 247)       // Secondary background
- Waveform: rgb(0, 122, 255)           // Accent color
- Label: rgb(142, 142, 147)            // Gray

Placeholder:
- Background: rgb(242, 242, 247)       // Secondary background
- Spinner: rgb(255, 59, 48)            // Red
- Text: rgb(142, 142, 147)             // Gray
```

### Dark Mode

```
Recording Banner:
- Background: rgba(255, 69, 58, 0.15)  // 15% red
- Border: rgba(255, 69, 58, 0.5)       // 50% red
- Dot: rgb(255, 69, 58)                // 100% red
- Ring: rgba(255, 69, 58, 0.3)         // 30% red
- Text: rgb(255, 255, 255)             // White
- Subtitle: rgb(142, 142, 147)         // Gray

Stop Button:
- Background: rgb(255, 69, 58)         // Red
- Text: rgb(255, 255, 255)             // White
- Shadow: rgba(255, 69, 58, 0.3)       // 30% red

Start Button:
- Background: rgb(10, 132, 255)        // Blue (accent)
- Text: rgb(255, 255, 255)             // White
- Shadow: rgba(10, 132, 255, 0.3)      // 30% blue

Import Button:
- Background: rgb(48, 209, 88)         // Green
- Text: rgb(255, 255, 255)             // White
- Opacity (disabled): 0.5              // 50%

Audio Level:
- Background: rgb(28, 28, 30)          // Secondary background
- Waveform: rgb(10, 132, 255)          // Accent color
- Label: rgb(142, 142, 147)            // Gray

Placeholder:
- Background: rgb(28, 28, 30)          // Secondary background
- Spinner: rgb(255, 69, 58)            // Red
- Text: rgb(142, 142, 147)             // Gray
```

---

## Spacing & Sizing

```
Recording Banner:
┌─ padding: 16pt all sides ────────────────┐
│  ┌─ spacing: 12pt ────┐                  │
│  │ [Dot]  [Text]      │                  │
│  └────────────────────┘                  │
└──────────────────────────────────────────┘
Border width: 2pt
Corner radius: 12pt

Audio Level Box:
┌─ padding: 16pt all sides ────────────────┐
│  Label                                    │
│  ↕ spacing: 8pt                          │
│  [Waveform - height: 80pt]               │
└──────────────────────────────────────────┘
Corner radius: 12pt

Placeholder:
┌─ height: 60pt fixed ─────────────────────┐
│        [Spinner]                          │
│        ↕ spacing: 8pt                    │
│        [Text]                             │
└──────────────────────────────────────────┘
Width: .infinity

Buttons:
┌─ padding: 16pt vertical ─────────────────┐
│  ┌─ spacing: 12pt ────┐                  │
│  │ [Icon]  [Text]     │                  │
│  └────────────────────┘                  │
└──────────────────────────────────────────┘
Padding horizontal: 0 (fills width)
Corner radius: 12pt

OR Separator:
[Line - height: 1pt] [Text - caption] [Line - height: 1pt]
Vertical padding: 8pt top and bottom
Horizontal: Fills width

VStack Spacing:
Between elements: 16pt
```

---

## Touch Targets

```
All buttons meet iOS minimum: 44pt × 44pt

Recording Banner:
┌─────────────────────────────┐
│ Height: 80pt                │ ← Exceeds minimum
│ Width: Full screen - 32pt   │
└─────────────────────────────┘

Stop/Start Button:
┌─────────────────────────────┐
│ Height: 52pt                │ ← Exceeds minimum
│ Width: Full screen - 32pt   │    (16pt padding + 16pt vertical)
└─────────────────────────────┘

Import Button:
┌─────────────────────────────┐
│ Height: 48pt                │ ← Exceeds minimum
│ Width: Full screen - 32pt   │    (14pt padding + 14pt vertical)
└─────────────────────────────┘
```

---

## Responsive Behavior

### iPhone SE (Small Screen)
```
┌────────────────────┐
│ Recording Banner   │ ← Full width
│ (compressed)       │
├────────────────────┤
│ Waveform (small)   │ ← 60pt height
├────────────────────┤
│ Stop Button        │ ← Full width
│ (normal)           │
├────────────────────┤
│ OR                 │
├────────────────────┤
│ Import Button      │ ← Full width
│ (dimmed)           │
└────────────────────┘

Everything stacks vertically
Maintains full functionality
```

### iPhone Pro Max (Large Screen)
```
┌────────────────────────────┐
│ Recording Banner           │ ← Full width
│ (comfortable spacing)      │
├────────────────────────────┤
│ Waveform (large)           │ ← 80pt height
│ (more detail visible)      │
├────────────────────────────┤
│ Stop Button                │ ← Full width
│ (normal)                   │
├────────────────────────────┤
│ OR                         │
├────────────────────────────┤
│ Import Button              │ ← Full width
│ (dimmed)                   │
└────────────────────────────┘

Same layout, more breathing room
```

### iPad (Large Screen)
```
┌──────────────────────────────────────┐
│ Recording Banner                     │ ← Centered with max width
│ (max-width: 600pt)                   │
├──────────────────────────────────────┤
│ Waveform                             │ ← Centered
│ (more bars visible)                  │
├──────────────────────────────────────┤
│ Stop Button                          │ ← Centered
│ (max-width: 600pt)                   │
├──────────────────────────────────────┤
│ OR                                   │
├──────────────────────────────────────┤
│ Import Button                        │ ← Centered
│ (max-width: 600pt)                   │
└──────────────────────────────────────┘

Elements centered with max-width
Prevents overstretching on large screens
```

---

## Summary

This visual guide shows:
- ✅ **4 complete screen states** from default to results
- ✅ **Detailed component closeups** with exact measurements
- ✅ **Animation sequences** with timing
- ✅ **Complete color palette** for light and dark modes
- ✅ **Spacing and sizing** specifications
- ✅ **Touch target sizes** (all exceed 44pt minimum)
- ✅ **Responsive behavior** across device sizes

The design is:
- **Clear** - Impossible to miss when recording
- **Professional** - Follows iOS design patterns
- **Accessible** - Large targets, high contrast
- **Responsive** - Works on all device sizes
- **Polished** - Animations and shadows add depth

Users will **immediately understand**:
- ✅ Recording is active (large red banner)
- ✅ What to do (clear instruction)
- ✅ How to stop (prominent red button)
- ✅ Why import is unavailable (dimmed with separator)
