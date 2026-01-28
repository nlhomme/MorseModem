# Clear All History - Visual Guide

## User Interface

### History View with Messages

```
┌─────────────────────────────────────────┐
│  🗑 Clear All      History         Edit │ ← Navigation Bar
├─────────────────────────────────────────┤
│  🔍 Search messages                     │ ← Search Bar
├─────────────────────────────────────────┤
│                                         │
│  ┌───────────────────────────────────┐ │
│  │ ↑ Encoded            2 hours ago  │ │
│  │ HELLO WORLD                       │ │
│  │ .... . .-.. .-.. ---  .-- ---...  │ │
│  └───────────────────────────────────┘ │
│                                         │
│  ┌───────────────────────────────────┐ │
│  │ ↓ Decoded            5 hours ago  │ │
│  │ SOS                               │ │
│  │ ... --- ...                       │ │
│  └───────────────────────────────────┘ │
│                                         │
│  ┌───────────────────────────────────┐ │
│  │ ↑ Encoded            1 day ago    │ │
│  │ TEST MESSAGE                      │ │
│  │ - . ... -  -- . ... ... .- --...  │ │
│  └───────────────────────────────────┘ │
│                                         │
└─────────────────────────────────────────┘
```

### When Clear All is Tapped

```
┌─────────────────────────────────────────┐
│  🗑 Clear All      History         Edit │
├─────────────────────────────────────────┤
│  🔍 Search messages                     │
├─────────────────────────────────────────┤
│                                         │
│  ┌───────────────────────────────────┐ │
│  │ ↑ Encoded            2 hours ago  │ │
│  │ HELLO WORLD                       │ │
│  │ .... . .-.. .-.. ---  .-- ---...  │ │
│  └───────────────────────────────────┘ │
│                                         │
│         ┌─────────────────────┐         │ ← Confirmation Dialog
│         │                     │         │   appears over content
│         │  Clear All History  │         │
│         │                     │         │
│         │ Are you sure you    │         │
│         │ want to delete all  │         │
│         │ 3 messages? This    │         │
│         │ action cannot be    │         │
│         │ undone.             │         │
│         │                     │         │
│         │  ┌───────────────┐  │         │
│         │  │    Cancel     │  │         │ ← Gray button
│         │  └───────────────┘  │         │
│         │  ┌───────────────┐  │         │
│         │  │  Clear All 🔴 │  │         │ ← Red button
│         │  └───────────────┘  │         │
│         └─────────────────────┘         │
│                                         │
└─────────────────────────────────────────┘
```

### After Clearing (Empty State)

```
┌─────────────────────────────────────────┐
│  🗑 Clear All      History         Edit │
│  (disabled)                    (disabled)│ ← Buttons grayed out
├─────────────────────────────────────────┤
│  🔍 Search messages                     │
├─────────────────────────────────────────┤
│                                         │
│                                         │
│             🕐                          │ ← Empty state icon
│                                         │
│          No History                     │
│                                         │
│   Your encoded and decoded messages     │
│   will appear here                      │
│                                         │
│                                         │
│                                         │
│                                         │
│                                         │
│                                         │
└─────────────────────────────────────────┘
```

## Button States

### Clear All Button (Enabled)
```
┌──────────────────┐
│ 🗑 Clear All     │  ← Red text, clickable
└──────────────────┘
```

### Clear All Button (Disabled)
```
┌──────────────────┐
│ 🗑 Clear All     │  ← Gray text, not clickable
└──────────────────┘
```

### Clear All Button (Pressed)
```
┌──────────────────┐
│ 🗑 Clear All     │  ← Slightly darker, touch feedback
└──────────────────┘
```

## Confirmation Dialog Variations

### Singular (1 message)
```
┌─────────────────────────────────────┐
│       Clear All History             │
│                                     │
│  Are you sure you want to delete    │
│  1 message? This action cannot      │
│  be undone.                         │
│                                     │
│  ┌───────────────────────────────┐  │
│  │         Cancel                │  │
│  └───────────────────────────────┘  │
│  ┌───────────────────────────────┐  │
│  │       Clear All 🔴            │  │
│  └───────────────────────────────┘  │
└─────────────────────────────────────┘
```

### Plural (Multiple messages)
```
┌─────────────────────────────────────┐
│       Clear All History             │
│                                     │
│  Are you sure you want to delete    │
│  all 15 messages? This action       │
│  cannot be undone.                  │
│                                     │
│  ┌───────────────────────────────┐  │
│  │         Cancel                │  │
│  └───────────────────────────────┘  │
│  ┌───────────────────────────────┐  │
│  │       Clear All 🔴            │  │
│  └───────────────────────────────┘  │
└─────────────────────────────────────┘
```

## Interaction Flows

### Flow 1: User Confirms Clear

```
User taps              Confirmation         User taps          All messages
"Clear All"    →      dialog appears   →   "Clear All"    →   deleted
button                with warning          (red button)       instantly

                                                         ↓
                                                    
                                                Empty state
                                                displayed
```

### Flow 2: User Cancels

```
User taps              Confirmation         User taps          Dialog
"Clear All"    →      dialog appears   →   "Cancel"      →   dismisses
button                with warning          button             

                                                         ↓
                                                    
                                                No changes
                                                made
```

### Flow 3: Button is Disabled

```
Empty history     →    "Clear All"      →    User tries    →    Nothing
exists                 button grayed         to tap             happens
                      out (disabled)         
```

## Animation Sequence

### Opening Confirmation Dialog

```
Frame 1:                Frame 2:                Frame 3:
List view              Dialog slides up         Dialog fully
normal                 from bottom             visible

│     List     │      │     List     │      │     List     │
│              │      │  ┌─────────┐ │      │  ┌─────────┐ │
│    Items     │      │  │ Dialog  │ │      │  │ Dialog  │ │
│              │  →   │  │ sliding │ │  →   │  │  full   │ │
│              │      │  │   up    │ │      │  │  shown  │ │
│              │      │  └─────────┘ │      │  └─────────┘ │
└──────────────┘      └──────────────┘      └──────────────┘
  (0ms)                 (150ms)               (300ms)
```

### Closing After Cancel

```
Frame 1:                Frame 2:                Frame 3:
Dialog shown           Dialog slides down      List normal
                                               again

│  ┌─────────┐ │      │              │      │              │
│  │ Dialog  │ │      │  ┌─────────┐ │      │     List     │
│  │  full   │ │  →   │  │ sliding │ │  →   │              │
│  │  shown  │ │      │  │  down   │ │      │    Items     │
│  └─────────┘ │      │  └─────────┘ │      │              │
└──────────────┘      └──────────────┘      └──────────────┘
  (0ms)                 (150ms)               (300ms)
```

### Deletion Animation

```
Frame 1:                Frame 2:                Frame 3:
Dialog shown           List items fade out     Empty state
                       and shrink              fades in

│  ┌─────────┐ │      │              │      │              │
│  │ Dialog  │ │      │   ░░░░░░░    │      │              │
│  │  shown  │ │  →   │   ░░░░░░░    │  →   │  Empty State │
│  └─────────┘ │      │   ░░░░░░░    │      │              │
│  [Items...]  │      │   (fading)   │      │              │
└──────────────┘      └──────────────┘      └──────────────┘
  (0ms)                 (200ms)               (400ms)
```

## Dark Mode Appearance

### Light Mode
```
┌─────────────────────────────────────────┐
│  🗑 Clear All (red) History        Edit │
├─────────────────────────────────────────┤
│  White/light gray background            │
│  Black text                             │
│  Light gray cards                       │
└─────────────────────────────────────────┘
```

### Dark Mode
```
┌─────────────────────────────────────────┐
│  🗑 Clear All (red) History        Edit │
├─────────────────────────────────────────┤
│  Black/dark gray background             │
│  White text                             │
│  Dark gray cards                        │
└─────────────────────────────────────────┘
```

## iPad Appearance

### iPad (Larger Screen)

```
┌───────────────────────────────────────────────────────────────┐
│  🗑 Clear All              History                       Edit │
├───────────────────────────────────────────────────────────────┤
│  🔍 Search messages                                           │
├───────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────────────────────┐  ┌──────────────────────┐  │
│  │ ↑ Encoded       2 hours ago  │  │ ↓ Decoded  5 hrs ago │  │
│  │ HELLO WORLD                  │  │ SOS                  │  │
│  │ .... . .-.. .-.. ---  .--... │  │ ... --- ...          │  │
│  └──────────────────────────────┘  └──────────────────────┘  │
│                                                               │
│                 ┌───────────────────────┐                     │
│                 │  Clear All History    │  ← Dialog appears   │
│                 │                       │    as popover       │
│                 │  Are you sure...      │    on iPad          │
│                 │                       │                     │
│                 │  [Cancel] [Clear All] │                     │
│                 └───────────────────────┘                     │
│                                                               │
└───────────────────────────────────────────────────────────────┘
```

## Accessibility with VoiceOver

### VoiceOver Announcements

```
User swipes to Clear All button:
VoiceOver: "Clear All, button, destructive"

User double-taps (activates button):
VoiceOver: "Clear All History dialog"
VoiceOver: "Are you sure you want to delete all 3 messages? This action cannot be undone."

User swipes to Cancel:
VoiceOver: "Cancel, button"

User swipes to Clear All:
VoiceOver: "Clear All, button, destructive"

User double-taps Clear All:
VoiceOver: "3 messages deleted"
VoiceOver: "No History. Your encoded and decoded messages will appear here."
```

## Dynamic Type Support

### Regular Size
```
┌────────────────────┐
│ 🗑 Clear All       │
└────────────────────┘
```

### Large Size (Accessibility)
```
┌─────────────────────────┐
│                         │
│  🗑  Clear All          │
│                         │
└─────────────────────────┘
```

### Extra Large Size
```
┌────────────────────────────────┐
│                                │
│      🗑                        │
│                                │
│      Clear All                 │
│                                │
└────────────────────────────────┘
```

## Color Palette

### Button Colors

**Clear All Button (Enabled):**
- Light mode: `systemRed` (#FF3B30)
- Dark mode: `systemRed` (#FF453A)

**Clear All Button (Disabled):**
- Light mode: `systemGray3` (#C7C7CC)
- Dark mode: `systemGray3` (#48484A)

**Confirmation Dialog:**
- Background: `systemBackground`
- Text: `label`
- Destructive button: `systemRed`
- Cancel button: `systemGray6`

## Touch Targets

### Minimum Sizes (iOS Human Interface Guidelines)

```
Clear All Button:
┌────────────────────────┐
│                        │  ← Minimum 44pt height
│   🗑 Clear All         │  ← Minimum 44pt width
│                        │
└────────────────────────┘
      (44pt × 44pt minimum)


Dialog Buttons:
┌──────────────────────────────┐
│                              │  ← Minimum 44pt height
│         Cancel               │  ← Full width for easy tap
│                              │
└──────────────────────────────┘

┌──────────────────────────────┐
│                              │  ← Minimum 44pt height
│       Clear All 🔴           │  ← Full width for easy tap
│                              │
└──────────────────────────────┘
```

## Error States (If Applicable)

### Network Error (Future Enhancement)
```
┌─────────────────────────────────────┐
│       Clear All History             │
│                                     │
│  Failed to clear history.           │
│  Please try again.                  │
│                                     │
│  ┌───────────────────────────────┐  │
│  │         OK                    │  │
│  └───────────────────────────────┘  │
└─────────────────────────────────────┘
```

### Partial Success (Future Enhancement)
```
┌─────────────────────────────────────┐
│       Clear All History             │
│                                     │
│  Cleared 14 of 15 messages.         │
│  1 message could not be deleted.    │
│                                     │
│  ┌───────────────────────────────┐  │
│  │         OK                    │  │
│  └───────────────────────────────┘  │
└─────────────────────────────────────┘
```

## Summary

The "Clear All" feature provides:
- ✅ **Clear visual hierarchy** - Red button indicates danger
- ✅ **Consistent placement** - Left toolbar position
- ✅ **Intuitive icons** - Trash icon is universally understood
- ✅ **Safe defaults** - Disabled when empty, confirmation required
- ✅ **Proper feedback** - Clear message about consequences
- ✅ **Platform conventions** - Follows iOS design patterns
- ✅ **Accessibility** - Works with VoiceOver and Dynamic Type
- ✅ **Responsive** - Adapts to different screen sizes
- ✅ **Professional** - Polished animations and transitions

This design ensures users can confidently manage their history while being protected from accidental data loss.
