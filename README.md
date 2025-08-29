# Pacebud Progress Log: August 29

## Progress Bar in Live Activity

Implemented a native iOS progress bar in Live Activities that dynamically shows user progress toward their running goals, with intelligent display logic based on goal type.

---

### What Was Built

- **iOS Models Extension**: Added `progress`, `progressKind`, and `progressLabel` fields to `PacebudActivityAttributes.ContentState` in both Runner and Widget targets
- **Flutter Bridge Update**: Extended `LiveActivityService.updateRunningActivity(...)` to include progress fields in the method channel payload
- **Smart Goal Detection**: Enhanced `live_activity_provider.dart` to automatically detect goal types and compute appropriate progress:
  - **Complex goals** (distance + time): Shows goal + projection + distance-based progress bar
  - **Distance-only goals**: Shows "X km run" + distance-based progress bar (no projection)
  - **Time-only goals**: Shows "X min run" + time-based progress bar (no projection)
  - **Quick runs**: No goal, no projection, no progress bar
- **SwiftUI Progress Bar**: Added progress bar at bottom of Live Activity that fills based on current progress toward target

---

### Technical Implementation

- **Progress Calculation**:
  - Distance progress: `currentDistance / targetDistance` (clamped 0.0-1.0)
  - Time progress: `elapsedSeconds / targetSeconds` (clamped 0.0-1.0)
  - Progress labels: "2.3/5.0 km" or "12:34/30:00" format
- **Goal Label Logic**:
  - Complex: "5.0 km in 25m 00s"
  - Distance-only: "Run 5.0 km"
  - Time-only: "30m run"
- **Projection Gating**: Projection row only shows for complex goals; hidden for simple goals to reduce UI clutter
- **Progress Bar Rendering**: Uses SwiftUI `GeometryReader` with `Capsule()` shapes for smooth, native iOS appearance

---

### Data Flow

1. **Flutter**: `live_activity_provider.dart` detects goal type and computes progress
2. **Bridge**: `LiveActivityService` sends progress data via method channel
3. **iOS**: `LiveActivityChannel.swift` receives and stores progress in `ContentState`
4. **SwiftUI**: Widget renders progress bar when `progress != nil`, hides projection when `predictedFinish == nil`

---

### What's Next
- Fix “Google Maps Authentication Failed”
    - After the loading of GPS, there's another loading screen. I think this might be solved with fixing this alert.
    - I hope this fix will also make these errors disappear:
```
flutter: LocationService: Starting location tracking...
 This method can cause UI unresponsiveness if invoked on the main thread. Instead, consider waiting for the `-locationManagerDidChangeAuthorization:` callback and checking `authorizationStatus` first.
flutter: LocationService: "Always" permission already granted.
 This method can cause UI unresponsiveness if invoked on the main thread. Instead, consider waiting for the `-locationManagerDidChangeAuthorization:` callback and checking `authorizationStatus` first.
 This method can cause UI unresponsiveness if invoked on the main thread. Instead, consider waiting for the `-locationManagerDidChangeAuthorization:` callback and checking `authorizationStatus` first.
```
- Fix goal displays (some say 'distance IN time', should say 'distance UNDER time').
- Sound effects for goal achievements.
- Save user's goal to the database.
- Save whether the user met their goal or not.
- Modify the weekly line chart to handle month and year.
- Maybe: Add weather data in home screen (there's a lot of dead space that I need to fill according to my friend Tristan). I'll see how viable it is to add this; most likely easy.
- Maybe: split average pace data during run
    - Split average pace line chart inside run info.
- Maybe: calories and other common data inside the run info.

---
#### (For earlier logs, see `PAST-LOGS.md`)