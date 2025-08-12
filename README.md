# Pacebud Progress Log: August 10th - August 12th 2025

## Transparent clipboard summary cards
### (branch: rs-cards)

- In **run_summary.card.dart**, I tried my best to keep all the elements in the copied image the same width, just because I like how that looks on my instagram story. Also normalized the pace so that it displays as "8:36 /mi" (example)

- In **current_run.dart**, I made it so that during the export we hide the background. This way, during the display I can see the data in a semi-transparent card, but the exported image is fully-transparent. Again, just because I like how this looks on my instagram story.

- I had an issue here that is later fixed with the super_clipboard package (read further for more)

---

## Every activity from the activities screen is now shareable (without the map)
### (branch: share-all-rs-cards)

- From the activities list, tapping the share button calls _showShareDialog(run), which opens a modal containing a RunSummaryCard wrapped in the same RepaintBoundary I use post‑run.

- For now, activities export without the map (MVP). The dialog still attempts to decode run['mapSnapshotBase64'] if it exists, but the default path is text‑only stats.

- Again, I had an issue here that is later fixed with the super_clipboard package (read further for more)

---

## Added dynamic measurement unit conversion for all runs
### (branch: dynamic-unit-conversion)

- In running_stats.dart, I made sure that every run displays distance and pace in the app’s currently selected unit (mi or km), even if it was originally recorded in the other unit.
    - Distance values are converted on the fly using the helper functions in distance_unit_conversion.dart:
        - kilometersToMiles() (already existed)
	    - milesToKilometers() (newly added)
	- Pace values are also re-computed to match the selected unit by feeding the converted distance into _computePaceString(), which returns a normalized format like 8:36/mi or 5:21/km.
	- Both the activities list and the share dialog now pull the stored unit (distanceUnitString) from Firestore and convert if needed.
    - If the stored value is null or invalid, it defaults to miles.
    - If distance is 0 or time is 0:00:00, pace displays as "---" instead of returning bad math.

---

## Introduced **Super_clipboard** package implementation
### (this branch)

- I had heard that the iOS Simulator can’t copy images to the clipboard and that base64 text would magically become an image on a real device. That’s not true. Both Simulator and device treat clipboard text as text. Apps like Instagram will paste a giant string (and may even crash). The goal here was to copy real image bytes. For this, I use the Flutter package **super_clipboard** to write PNG bytes directly to the system clipboard (works on iOS/Android/macOS/Windows). On Android you need minSdk 23 and the plugin’s ContentProvider in AndroidManifest with authorities matching your applicationId. On iOS it uses UIPasteboard without extra Info.plist keys.

---

## Up next:

(!!!) = most important
(!) = least important

- (!!) I’m going to try to display live run stats in an iOS Live Activity. This is crucial because the app must be interactive during the run and no one (me included) wants to keep opening the app. Since I'm building in Flutter, I’m not doing a smartwatch extension (for now).
    - My plan:
        - Ship a phase 1 with local Live Activity updates while background location is active. This should work for short-to-medium runs, but from what I've read, after some time iOS shuts down the app and it can’t send info locally.
        - If long runs still freeze updates, I’ll add a small, focused backend (e.g., Firebase Functions or AWS Lambda) to send APNs Live Activity updates so the lock screen continues to refresh even if iOS suspends the app.

- (!) Improve Stats:
    - I would like to have split pace information available (maybe some graph bars)
    - Show weekly running stats (runs, hours, miles, etc)

- (!!!) Give the ability to change the pace goal mid-run
- (!) Make the process to start running faster (remember last goals per distance, maybe?)


(For earlier logs, see `PAST-LOGS.md`)