# Pacebud Progress Log: August 15-19th

## iOS Live Activities (Lock Screen + Dynamic Island)

---

## Notes from developer

I finally implemented iOS Live Activities so I can see my run without unlocking the phone. I am going to try to be as detailed as possible for future reference.

First of all, to achieve this I needed to have background location tracking working (see past commit "background-location-tracking-fix")

- Tested outside.
- Data constantly updates and looks really pretty.
- I ran 10 miles in 1:42 minutes and the live activity worked really good. I started with 100% battery and ended the run with 83%. For the time I ran I think this is great battery usage.
- I only need to improve the esthetics. The text is way too small to be deciphering mid-run.
- Data formatting could also improve (Ex. '1h 40m' instead of '1h 40m 00s').
- The finish time projection accurately displays the finish time, it made me want to to faster at many times of the run, which is the main objective of the app. Nice.

---

I (sort of) followed these instructions given by Google's Gemini:

> - Need iOS 16.1+
> - Add a Widget Extension:
>     - Go to File > New > Target… > Widget Extension.
>     - Name the extension (e.g., "com.orzan.pacerunner.PacebudWidgetExtension").
>     - Ensure "Include Live Activity" is selected.
>     - Click Finish (and "Don't Activate" if prompted to activate the scheme).
> - Configure Info.plist (main app target):
>     - Add the "Supports Live Activities" key (Boolean, set to YES).
>     - If needing frequent updates, add "NSSupportsLiveActivitiesFrequentUpdates" (Boolean, set to YES).
> - Define ActivityAttributes:
>     - Create a structure (e.g., PacebudActivityAttributes) in your Live Activity file (e.g., PacebudWidgetLiveActivity.swift).
>     - This structure will describe the static and dynamic data for your Live Activity.
> - Add your Main Target to Live Activity Target Membership:
>     - Open the Inspector panel on the right side of Xcode.
>     - Add your main app target to the "Target Membership" list for the Live Activity file.
> - Implement Live Activity Configuration and Lifecycle (within your main app):
>     - Use ActivityKit to start, update, and end your Live Activities.
>     - You'll request the activity, then send updates to it as needed.
> - Customize User Interface:
>     - Design the appearance of your Live Activity using SwiftUI in the generated Live Activity file.
>     - Consider each presentation: compact (Dynamic Island), minimal (multiple activities), and expanded (Lock Screen).
>     - Use Xcode Previews to iteratively refine the UI.

Note: The only thing I did not follow was the single ActivityAttributes definition. Read more about this down below.

---

## What I built
- iOS widget UI & model
  - `ios/com.orzan.pacerunner.PacebudWidget/LiveActivities/PacebudActivityAttributes.swift` — Data model duplicated for the Widget target. Fields: distance, distanceUnit, elapsedTime, pace, isRunning, goal?, predictedFinish? (optional).
  - `ios/com.orzan.pacerunner.PacebudWidget/com_orzan_pacerunner_PacebudWidgetLiveActivity.swift` — SwiftUI layouts for Lock Screen + Dynamic Island. Renders goal and predicted finish when available. Includes `.widgetURL("pacebud://open")` for optional deep link.

- Flutter → iOS bridge
  - `lib/services/live_activity_service.dart` — MethodChannel API: start/update/end/availability. `updateRunningActivity(...)` now also sends `goal` and `predictedFinish`.
  - `lib/widgets/live_activity_provider.dart` — Listens to run state, distance, timer, and the goal/prediction providers; pushes updates to iOS. Builds `goal` like "10.0 mi in 1h 40m 00s" and reads `projected_finish_provider.dart` for `predictedTime`.
  - `lib/widgets/current_run.dart` — Initializes `liveActivityProvider` in `initState()` so updates start when the run starts.

- iOS native channel (Runner target)
  - `ios/Runner/LiveActivityChannel.swift` — Starts/updates/ends the activity using ActivityKit; keeps a local copy of `PacebudActivityAttributes` (same fields as the Widget target). Parses `goal` and `predictedFinish` from Flutter and passes them through.
  - `ios/Runner/AppDelegate.swift` — Registers the channel when iOS ≥ 16.2.
  - `ios/Runner/Info.plist` — Enables Live Activities and frequent updates.

---

## How it works (flow)

- Data sources: `distanceProvider`, `formattedElapsedTimeProvider`, `stableAveragePaceProvider`, `runStateProvider`.
- Extras:
  - `goal` = `targetDistanceProvider` + `formattedUnitString` + `formattedTargetTimeProvider`.
  - `predictedFinish` = `projected_finish_provider.dart` (`projectedTime`).
- `live_activity_provider.dart` listens to all of the above and calls `LiveActivityService.updateRunningActivity(...)` whenever something changes.
- iOS channel (`LiveActivityChannel.swift`) updates the Live Activity state; SwiftUI renders it on Lock Screen / Dynamic Island.

---

## iOS setup checklist

- Main app `Info.plist`:
  - `NSSupportsLiveActivities` = true
  - `NSSupportsLiveActivitiesFrequentUpdates` = true
- Capability: enable “Live Activities” on the Runner target.
- Register the plugin in `AppDelegate.swift` (gated with `#available(iOS 16.2, *)`).
- Optional: add a URL scheme `pacebud` under `CFBundleURLTypes` if you want the Live Activity tap to open the app (`.widgetURL("pacebud://open")`).

---

## Data model (duplicated on purpose)

- I keep a separate `PacebudActivityAttributes` in each target to avoid cross-target headaches:
  - Runner: `ios/Runner/LiveActivityChannel.swift`
  - Widget: `ios/com.orzan.pacerunner.PacebudWidget/LiveActivities/PacebudActivityAttributes.swift`
- Keep the fields in sync when you add/remove stuff.

### Fields

- distance: Double
- distanceUnit: String ("km" | "mi")
- elapsedTime: String ("hh:mm:ss")
- pace: String (e.g., "5:05/km" or "8:10/mi")
- isRunning: Bool
- goal?: String (e.g., "10.0 mi in 1h 40m 00s")
- predictedFinish?: String (e.g., "1h 43m 00s")

---

## UI quick notes

- Lock Screen shows the main metrics; right column can show goal/predicted when present.
- Dynamic Island (expanded bottom) shows `Pace`, `goal`, and `predicted` stacked.
- Status dot: green = running, orange = paused.

---

## How to test (real device)

- Live Activities don’t work on the simulator.
- Build/run on an iPhone (iOS 16.2+ recommended).
- Start a run → lock the device → watch distance/time/pace update. If a goal is set, you’ll also see the goal and the predicted finish time.

---

## iOS version notes

- ActivityKit exists in iOS 16.1, but `end(... dismissalPolicy:)` requires 16.2. I gate the native channel with `@available(iOS 16.2, *)` and recommend Deployment Target ≥ 16.2.
- If supporting 16.1, keep `areActivitiesAvailable` checks and guard the 16.2-only calls or use a fallback ending.

---

## Control Widget (iOS 18)

- `com_orzan_pacerunner_PacebudWidgetControl` uses the new iOS 18 Control Widgets APIs. Either guard it with `@available(iOS 18.0, *)` or set the widget extension deployment target to iOS 18.

---

## Troubleshooting

- “Cannot find LiveActivityChannel in scope” → Add `LiveActivityChannel.swift` to the Xcode project and ensure target = Runner.
- “No such module 'com_orzan_pacerunner_PacebudWidget'” → Don’t import the widget target in Runner. I duplicated the attributes on purpose.
- “end(:dismissalPolicy:) is only available in iOS 16.2 or newer” → Gate with `@available(iOS 16.2, *)` and use `.immediate`.
- “Object file built for newer iOS version” (pods) → Raise Runner/Pods deployment target or update the plugin. Often just a warning.

---

## Intructions to add new data fields

1) Compute it in Flutter
- Prefer a provider so it stays the single source of truth (like `projected_finish_provider.dart`).

2) Send it over the bridge
- Extend `LiveActivityService.updateRunningActivity(...)` and include it in the payload.

3) Receive/store on iOS
- Parse the new field in `LiveActivityChannel.swift` and add to `ContentState` in both attributes files (Runner + Widget).

4) Render in SwiftUI
- Update the lock screen / Dynamic Island sections in the widget file.

5) Make it reactive (optional)
- Also listen to the provider(s) in `live_activity_provider.dart` so the Live Activity updates automatically.

Why this flow? Clear separation of concerns (Flutter owns data, iOS owns presentation), one place per piece of logic, and small repeatable edits across 4 places, so future changes are fast and low‑risk.


---

## What's Next:

- (Updated) I've already defined my MVP:
    - ✅ Live activity with stats and time finish projection
    - Split pace (optional)
    - Only one goal: run under X time
    - Change goal when run is paused
    - Show projection time and turn text red when above X time
    - Unified home/stats screen with a 'tap to view more' button. Will improve the UI/UX.
    - Weekly snapshot summary above the stats
    - Save the goal to firebase
    - Show the goal in the shareable summary card, add the option to take it off in case user did not meet their goal.
    - Add a sound whenever the user goes above the finish time goal (maybe a bark since the mascot is a dog)

- In the next update I will update the UI of the live activity based on some planed visuals I prepared in Canva, then proceed to the rest of the checklist above.


(For earlier logs, see `PAST-LOGS.md`)