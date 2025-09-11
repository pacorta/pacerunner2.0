# Pacebud Progress Log: September 10th, 2025


# Prediction Goal Display Color Updates

- **Green indicator for good performance**: Display now turns green when user is running faster than their target pace (lower time = better performance)
- **Finalized state handling**: When user reaches target distance in complex goals, projection freezes and shows final time with appropriate color coding
- Also refactored unit conversions for better code maintainability.

# GPS Distance Filtering

## Problem Statement

I've learned that many tracking apps suffer from the same issue: GPS location data "jitters" when the user is not moving; it's like it's trying to find the correct spot. You can actually spot this on any running app, just start a run, don't move and you'll see false tracking movements.

Problems this causes:
- **False distance accumulation**: Users standing still accumulate false distance because of fake tracking when "jittering", worsening the UX.
- **Inaccurate fitness metrics**: Corrupted pace, speed, and route data

## Solution: Anchor-Gate Filtering
I had no idea how this was going to be solved. After hours of consulting with GPT-5 and Claude Sonnet 4, I implemented an **anchor-gate filtering system** that eliminates GPS noise while maintaining responsiveness to real movement.

### Core Algorithm

It keeps a fixed “anchor” point and only counts distance once you move far enough away from it:

```dart
// Key filtering constants
const double kRejectAccuracy = 35.0;    // Reject poor GPS readings
const double kMinStepFloor = 3.0;       // Minimum movement threshold (meters)  
const double kMinStepCeil = 12.0;       // Maximum movement threshold (meters)
const double kAccFactor = 0.5;          // Accuracy scaling factor
const double kGoodAccCutoff = 10.0;     // High-precision GPS threshold
const double kSpeedMax = 15.0;          // Maximum realistic speed (m/s)
```

### What we filter out

1. **Bad accuracy**: Anything worse than 35m.
2. **Teleport speeds**: Reject speeds > 54 km/h.
3. **Smart threshold**: The movement threshold adapts to GPS quality:
   - Great GPS (< 10m): 2m threshold
   - Normal GPS: 3–12m depending on accuracy right now
4. **Anchor timeout**: If you’re idle for 30s, the anchor resets.

### Other Features

#### State‑aware re‑anchoring
```dart
// Reset anchor on pause/resume to prevent false distance accumulation
if (runState == RunState.paused || 
    (runState == RunState.running && _previousRunState == RunState.paused)) {
  _anchorLocation = null;
}
```

#### Timestamps
If a timestamp is missing, we skip velocity checks but still keep the distance filter working.

## Results

### Before Implementation
- Stationary users: ~0.15 km phantom distance per hour
- Noisy distance readings during slow movement
- Distance "jumps" when resuming from pause

### After Implementation  
- Stationary users: 0.00 km accumulated distance
- Responsive to real movement (detects walking within 2-5 seconds)
- Smooth distance tracking through pause/resume cycles
- Accuracy within ±5% of actual distance traveled

## Technical Benefits

**Anchor‑gate vs incremental filters:**
- Incremental filters reject noisy points but still let error build up over time
- Anchor‑gate only counts real displacement from a fixed point
- Net: no noise creep, still responsive

**Adaptive Thresholds:**
- GPS accuracy varies by environment (urban canyons, open sky, etc.)
- Filter automatically adjusts sensitivity based on current GPS quality
- Maintains optimal balance between noise rejection and movement detection

## Configuration

You can tweak everything at the top of the implementation:

```dart
// Adjust these values to fine-tune filter behavior
const double kMinStepFloor = 3.0;       // Decrease for higher sensitivity
const double kMinStepCeil = 12.0;       // Increase for more noise tolerance  
const double kAccFactor = 0.5;          // Adjust accuracy scaling
```


### What's Next
- I need to add more login services + a test login for an apple reviewer.
- Fix issue: when after not on a run, app keeps tracking user's location (have blue GPS indicator on). Hours after completing the run/not being active.
- Make sure to save in the database whether the user reached their goal or not, how long it took them, or how far where they off completing it 
- Launch for real user testing
- Add sound alerts
- Add split pace stats + charts

---
#### (For earlier logs, see `PAST-LOGS.md`)