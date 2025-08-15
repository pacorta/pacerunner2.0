# Pacebud Progress Log: August 13-14th
## Background Location Tracking Fix (iOS)

After a test run revealed that location tracking stopped when the iPhone was locked, several changes were made to ensure continuous, accurate background tracking.

---

## Permission Management System

- Add request "Always" permission (not just "When in use") to the existing flow (`location_service.dart`)
- Added native iOS authorization status checking to distinguish between "Always" and "When In Use" permissions (the location plugin doesn't distinguish between them - both return "granted") (`native_location_manager.dart`, `LocationManagerChannel.swift`)
- Automatic "Always" permission request - if user only grants "When In Use", we automatically show the second iOS prompt to upgrade to "Always" (`location_service.dart`)
- When user has permanently denied permissions, we take them to settings and we stop initialization until user comes back with permissions (`location_service.dart`)

---

## Native iOS Location Manager (Method Channel)

- Created a Method Channel to communicate directly with the Location Manager (native of iOS) (`LocationManagerChannel.swift`, `native_location_manager.dart`)
- In this method channel we implemented:
    - activityType = .fitness
    - allowsbackgroundLocationUpdated = true: allows for continuous tracking in background
    - pausesLocationUpdatesAutomatically = false: helps avoid iOS pause of tracking automatically
    - showsBackgroundLocationIndicator = true (iOS 11+): blue GPS indicator for transparency
- Registered custom location manager channel in AppDelegate.swift (`AppDelegate.swift`)
- Added native_location_manager.dart for compatibility
- Added native methods to location_service.dart to improve new flow

---

## Background Location Configuration

- Added the background capability for location updates (`Info.plist`)
- Background location config (`location_service.dart`):
    - enableBackgroundMode(enable: true) - Enables background location tracking
    - LocationAccuracy.navigation - Highest accuracy level (like fitness activity type)
    - 1000ms interval and 5meter distance filter (for now, not sure if these are good)

---

## Smart Pause/Resume System

- During pause/resume: Added a system to reduce battery usage by reducing the frequency when the run is paused (only updates every 20m) (`location_service.dart`, `current_run.dart`)
- Set fitness activity type for better accuracy

---

## Error Handling & Recovery

- I made stopLocationTracking() async so that it waits for enableBackgroundMode(false) and disableBackgroundLocation() to be completed (`location_service.dart`)
- Considered different cases in which the GPS is not correctly gathered, such as if the user disables Location Services mid run, or the GPS signal is too weak, etc. These would break the stream (`location_service.dart`)
- Location service recovery system - if user disables Location Services mid-run, the app attempts automatic recovery and shows helpful UI messages (`location_service.dart`, `current_run.dart`)
- Implemented race condition protection with `_isStopping` flag to prevent multiple simultaneous stop calls (`location_service.dart`)

---

## StreamController Architecture Fix

- During these changes I realized that, since my streamController is static, and that if I call dispose() and then want to initialize another run during the same session of the app, it will already be closed. To fix this I made two types of cleanup: reset(), and dispose() (`location_service.dart`)

---

## Things for later

- I found that iOS ignores interval, and mostly uses distanceFilter: "In iOS, interval doesn't dictate everything; the distance filter and the accuracy do". Since we have distanceFilter set to 5m, if battery usage becomes an issue, we can increment to 10m

- Backoff based on speed: We know that distanceFilter set at 5m is good for testing, but maybe we can go up to 10-15m when speed is constant, then go back to 5m if we detect sudden changes (accelerating/stopping)

- Precise vs Approximate Location (iOS 14+)
    - Even with permission, users can have Precise Location off (reduced accuracy). Two native helpers exposed:
        - accuracyAuthorization() → returns full or reduced
        - requestTemporaryFullAccuracy(reasonKey) → requests temporary full accuracy with text in Info.plist (NSLocationTemporaryUsageDescriptionDictionary)
    - Use this if reduced accuracy is detected during an active run

- Resilient Resubscription
    - In onError, after re-enabling service, recreate the listener if it dropped:
        _locationSubscription?.cancel();
        _locationSubscription = _location.onLocationChanged.listen(...);

---

## Bugs

- When user clicks to not allow for location tracking, they can still track a run without data

---

## Other Changes

- Switched identifier from legacy name 'Pacerunner' to 'Pacebud' (`Info.plist`)

---

## Test Results
- Background tracking continues when the iPhone is locked.
- Blue GPS indicator is visible during background operation.
- Polyline map updates smoothly without jumping between points.
- Successfully tested on both simulator and physical device.

---
## What's Next:

- I've already defined my MVP:
    - Live activity with stats and time finish projection
    - Split pace
    - Only one goal: run under X time
    - Change goal when run is paused
    - Show projection time and turn text red when above X time
    - Unified home/stats screen with a 'tap to view more' button. Will improve the UI/UX.
    - Weekly snapshot summary above the stats
    - Save the goal to firebase
    - Show the goal in the shareable summary card, add the option to take it off in case user did not meet their goal.


(For earlier logs, see `PAST-LOGS.md`)