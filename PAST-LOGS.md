7/12/24

	•	📍 The app can now detect the device's current location and speed (in m/s).

7/13/24

	•	📱 The app detects the device's current location, but accuracy needs improvement (still buggy).
	•	Speed detection improvements:
		•	Detects speed in m/s, but I need to convert this to mph.
		•	Successfully runs on an iPhone.
	•	💡 Note for new devices: Go to Settings > Security & Privacy > General Tab, click "iproxy was blocked," then click Open Anyway to allow iproxy to run.
	•	🗺️ Adds polyline points to mark the route taken during the session.

7/18/24

	•	The app now accesses speed information from the Map widget in the currentRun widget.
This was achieved using the Riverpod package for state management, which will be useful for displaying travel statistics elsewhere in the app.

7/19/24

	•	Speed is now displayed in mph instead of m/s.

8/7/24

	•	✨ New Features:
		•	The app calculates user's traveled distance from Start Running
		•	Post-run stats popup with total distance
	•	🔄 Technical Updates:
		•	Transitioned to global state management
		•	Improved tracking control with state-driven approach

To-Do List ✅

	•	Create a summary page that includes the following:
	•	Total trip's polyline representation
	•	Average Pace
	•	Total Distance
	•	Time Elapsed
	•	Main Goal: Add a progress bar that compares the user's actual speed to an ideal speed:
	•	[—————(Actual Pace: Too Slow)————————(Best Pace)————(Actual Pace: Too Fast)—————]
	•	Remove the ability to go back to the home screen using the back arrow or sliding back, as this can cause data loss.

8/12/24

	•	⚙️ Added unit selection (miles/kilometers) on Home Screen
	•	📊 Added pace calculations:
		•	Pace1 = hr/distance
		•	Pace2 = distance/hr
	•	📸 Discovered captureMapScreenshot() functionality

To-Do List

	•	Summary page to include:
	•	Total trip's polyline representation (possibly using captureMapScreenshot())
	•	Pace1
	•	Pace2
	•	Total Distance
	•	Time Elapsed
	•	Main Goal: Add a progress bar to compare the runner's speed to an ideal speed.

Resources:

	•	[Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
	•	[Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the [online documentation](https://docs.flutter.dev/), which offers tutorials, samples, guidance on mobile development, and a full API reference.


9/24/2024

	•	🎯 PaceBar Implementation:
	1.	Created a file for current_pace, which calculates the pace over a small time window.
	2.	Required the current pace in seconds to animate the pace bar accurately.
	•	Initially considered extracting the data from current_pace.dart using StateNotifier, but this was more complex than using StateProvider.
	•	Decided to use two distinct StateProvider files (current_pace and current_pace_in_seconds), simplifying the code and reducing the chance of bugs.
	3.	Made aesthetic changes to the PaceBar, including smoothing the animation. The animation now recreates itself with each pace change, starting from the current position and moving to the new one.
	4.	Implemented error handling: if the app receives an invalid pace (e.g., 0 or negative), the widget retains the last known valid position to prevent UI issues.
	5.	Created Normalized Pace to convert raw pace data (in seconds per mile) into a value between 0 and 1:
	•	Formula: 1 - (paceInSecondsPerMile - minPace) / (maxPace - minPace) normalizes the pace.
	•	The clamp(0.0, 1.0) call ensures the normalized pace stays within a valid range.
	•	Using the normalized value for rendering ensures a visually intuitive PaceBar, regardless of the specific pace range.
	•	Overall, this update works well. It was tested in real life and responded accurately to walking, jogging, and sprinting.
	•	Currently, the app sets the default optimal pace at 8 minutes per mile, but this can be customized. Eventually, the user will be prompted for their running goal, but this feature will be added after the data section is complete.



10/14/2024

	•	🔗 Database Integration:
		•	Merged database with front end
		•	Added login screen and run history
	•	🐛 Known Bugs:
			•	When the user press 'stop running', the app keeps tracking the run even after sending the correct summary data to the running stats screen.To fix this I think I either need to:
				-Find the call that told the map to stop tracking (pretty sure it was called stopTracking) and find out how to call it with the button from currentRun
				-or double the power of whatever is making it stop eventually, because it does *eventually stop*. By this I mean attempting to activate that stop sooner.
			•	After having to upgrade to ios 15 becuse of dependency issues, I got the following messages in 'LocationPlugin' in the ios folder:
				- [CLLocationManager authorizationStatus] 		error---->>	'authorizationStatus' is deprecated: first deprecated in iOS 14.0
				- [CLLocationManager locationServicesEnabled]	error---->> 'This method can cause UI unresponsiveness if invoked on the main thread. Instead, consider waiting for the `-locationManagerDidChangeAuthorization:` callback and checking `authorizationStatus` first.'

12/16/24: UI + Security Update

	•	🛠️ Fixed bugs:
			•	Distance unit conversion: Pace unit now updates correctly when switching distance units after run completion
			•	Run data persistence: Resolved issue where previous run data was displaying in current run screen
				•	Note: PaceBar still shows some residual data from previous runs
			•	API Key Security: Integration of dotenv to hide api keys and other sensitive data.
	
	•	📝 Lessons Learned:
			•	This project has taught me the importance of secure development practices and clean coding standards:
				•	I successfully implemented dotenv to manage sensitive information like API keys, ensuring that future development adheres to security best practices.
				•	I now proactively approach projects with a focus on secure and maintainable code.
	•	🔄 In Progress:
			•	Adding vibration feedback for pace notifications

	•	✅ To-Do:
			•	UI improvements for running screen, with focus on PaceBar enhancement for clarity and usability.
			•	Resolve pace tracking issues:
				•	Current pace and current pace in seconds not updating properly
				•	Consider consolidating pace states in providers for better PaceBar integration
			•	Take advantage of the variance calculations (difference between current pace and target pace) to create difficulty levels (easy, medium, hard).
			•	Add advanced visualizations, like post-run heatmaps to analyze pace trends.

	•	🤖 Android Configuration Setup:

			While the app currently focuses on iOS development, the Android configuration has been set up for future compatibility. The setup includes:

			•	Configured Gradle build system with Firebase integration
			•	Set up Google Services plugin in the following files:
				•	`android/settings.gradle`
				•	`android/app/build.gradle`
				•	`android/build.gradle`

			This configuration will simplify future Android deployment when needed, but is not actively used in the current development phase.

			Note: The app currently targets iOS development, and Android-specific features are not implemented yet.


7/9/2025: 

	•	Fixed bugs:

			•	Fixed state leakage after saving a user's run.
					- This was done by creating functions resetCurrentPaceProvider() and resetCurrentPaceInSecondsProvider().
					- These functions eliminate the memory leak and guarantee indempotent state initialization (term that I recently learned).
					- Lesson learned: In flutter/riverpod, everything in the state should live inside the provider graph. Global variables break the reactivity model and cause edge cases like these.
			
			•	Fixed state leakage after pressing 'stop' button.
					-This was done by re-positioning the tracking provider being false immediatly after pressing 'stop'; this stops the GPS and polyline at the same time and the stats are captured with final values. No more data leakage during the dialog.
			•	Fixed UI/UX issues during the pace selection part of the flow.
					-Added a limit to 999 units of distance
					-Shapes don't overflow anymore
			•	Standardized pace calculation intervals across providers: Resolved timing inconsistency where current_pace_provider.dart used 4-second intervals while current_pace_in_seconds_provider.dart used 3-second intervals. Both providers now use consistent 4-second windows for pace calculations, ensuring synchronized PaceBar animations and display metrics.
			

	•	Comments/Braindump/Vent: 

			Throughout this project I have been very insecure mainly because I always think this is not good enough for an MVP. But at least I have to launch it, then iterate on top of that. It might be embarrasing to launch a bad app, but at least that's better than never launching.


	•	MVP Development Checklist:

			•	What currently works:
				- GPS tracking and polyline ✓
				- Basic pace calculation ✓ 
				- Visual PaceBar ✓
				- Firebase auth/storage ✓
				- Pace selection flow ✓

			•	To-Do (Must complete for MVP):
				1. Add GPS strength indicator with connection status (weak/strong/acquiring)
				2. Implement user-location-fetching pre-warming during pace selection flow
				3. Add pause/resume functionality with proper state management
				4. UI/UX improvements (next section)

			•	UI/UX Improvements:
				1. Implement play/pause/stop function.
				2. Add current goal header display ("1 mile in 8 minutes")
				3. Add a calculating-wheel for the current pace data. (If we gather this every 4 seconds, the wheel should fill every 4 seconds, then reset). This adds transparency with the user.
					3.1. Add a grace period to start calculating current pace (don't calculate if the user is not yet moving)
				4. Restructure current_run.dart layout to match professional design
				5. Integrate map view seamlessly with new layout

			•	Minimum improvements for MVP:
				- GPS pre-warming to improve UX significantly.
				- "Calculating pace" UI to avoid user confusion.
				- Grace period of time or distance


	•	Ideas:

			•	Have several run-modes in the app:
				•	Make this whole concept of "current pace" into one of the ways to run with this app, call it "Time-Objective Run" or something.
				•	I think the main/best run will be when you set the pace you want to be running at, and you have two buttons (higher/lower). If you set it to 10mph and you are running at a pace of 8, then you are in the red zone because it's too fast. If you feel well in the pace of 8mph, then you can easily adjust your new green zone. This will just be another one in the many run-modes this app will have.
				•	Add another fun mode like "dog-chase" or "zombie-chase" where you have to outrun them. They could switch the pace at random times and you will be notified to hurry or they catch you.

			•	Add fun features or facts about the running stats:
				•	"Based on your running stats, you could outrun this animal" (reference: https://www.runguides.com/event/21604/find-your-strength-5k)
				•	"Only x% of the world is able to run a distance this long!"


7/21/2025:

			•	Added real-time GPS strength indicator with color-coded status (strong/good/weak/acquiring) using location accuracy data from map.dart.

			•	To-Do (Must complete for MVP)
				1. [√] 	Add GPS strength indicator with connection status (acquiring/weak/good/strong) 
				2. 		Implement user-location-fetching pre-warming during pace selection flow
				3. 		Add pause/resume functionality with proper state management
				4. 		UI/UX improvements

7/22/2025:

		•	GPS Pre-warming Implementation: Solved GPS delayed start during the start of the run by, instead, implementing location fetching during pace selection process.

				• Created LocationService to centralize all GPS operations across the app
				• Moved GPS initialization from CurrentRun screen to PaceSelection screen  
				• Eliminated 3-10 second GPS delay when users press "Start Running"
				• Made it modular for (potential) alternate run modes in the future.

			•	How this was achieved:
				• LocationService.dart: Static class using StreamController.broadcast() for multiple widget listeners
				• PaceSelection widget: GPS starts warming in initState(), continues during user configuration
				• Map widget: Converted from GPS owner to GPS consumer, listens to existing LocationService stream
				• Smart cleanup: Only stops GPS if user exits without completing run setup

			•	Technical challenges solved:
				• Riverpod lifecycle issue: "Cannot use ref after widget disposed" error when stopping GPS
				• Solution: Added try-catch blocks around provider updates in LocationService
				• Stream management: Replaced direct GPS subscriptions with broadcast stream architecture

			•	Lessons learned:
				• Static services holding widget references need defensive programming (try-catch)
				• StreamController.broadcast() enables multiple listeners to same GPS stream
				• GPS pre-warming improves UX a lot.
				• Singleton pattern with static methods provides clean service layer without constructor overhead

			•	Result: Users now experience instant GPS lock when starting runs, significantly improved UX flow.

		•	To-Do (Must complete for MVP):
			1. [√] 	Add GPS strength indicator with connection status (acquiring/weak/good/strong) 
			2. [√] 	Implement user-location-fetching pre-warming during pace selection flow
			3. 		Add pause/resume functionality with proper state management
			4. 		UI/UX improvements


7/23/2025:

	•	Pause/Resume/Stop Implementation: Added complete state management for running sessions with proper timer control and correct data handling.

		• Created RunState enum (notStarted, running, paused, finished) for clear session state management
		• Implemented PausableTimer class to handle timer that keeps accumulated time across pause/resume cycles
		• Updated CurrentRun screen to use state-driven approach instead of manual Stopwatch/Timer management
		• Dynamic UI buttons based on run state: PAUSE (when running) or RESUME/FINISH (when paused)

		How this was achieved:
		• RunStateProvider: Central state management for overall run status with derived providers for UI logic
		• PausableTimerProvider: Custom timer that tracks accumulated time and session start time separately
		• Map widget integration: Distance only accumulates during RunState.running, preventing wrong data during pause
		• Location tracking continuity: GPS updates continue during pause to prevent distance jumps on resume

		Technical challenges solved:
		• Race condition in _endRun(): Fixed order of operations to capture final data before resetting timer state
		• Distance accumulation during pause: Added conditional logic to only track distance when actively running
		• Distance jumping on resume: Maintained continuous location history even during pause state
		• Timer state consistency: Replaced multiple elapsed time providers with one unified system

		Lessons learned:
		• Order of operations is very important when capturing final state before cleanup
		• Separating data collection (GPS) from data processing (distance calculation) prevents edge cases
		• State-driven UI design scales better than manual button state management
		• Having one place for timer data prevents provider synchronization issues

		Result: Users can now pause runs without losing data accuracy, with proper time tracking and distance calculations.

	•	To-Do (Must complete for MVP):
			1. [√] 	Add GPS strength indicator with connection status (acquiring/weak/good/strong) 
			2. [√] 	Implement user-location-fetching pre-warming during pace selection flow
			3. [√]	Add pause/resume/stop functionality with proper state management
			4.		'Calculating wheel' for current pace
			5.		Grace period in the beginning for pace calculation
			6. 		UI/UX improvements


7/25/27:
	•	Performed small UI/UX Changes


7/26/27:

	•	No changes done, but I've realized a couple of things during the past few days:
		•	I talked to ChatGPT about my pre-warming approach because I was unsure if that's the industry-standard; I came to the realization that this is just me over-engineering everything. Apparently, apps like Strava or Nike Run Club just add a "loading" sign. This is way more effective and error-proof.
		•	For months I've been thinking about how the current pace automatically discards the rest of the run. I think this was another case of me over-engineering (or overthinking). Obviosuly the industry standard 'average pace' takes the whole run into account + the most recent changes.
			•	I think I am going to use the average to show the answer to the question "given everything I've ran so far, how long am I going to take to finish my goal if I keep running the same?". This is a question I always ask myself mid-run and at least this tool would be useful to me.
			•	Another run-mode I am thinking of is to have a speedometer. If the user wants to keep running at a certain pace, the app will notify them if they're off-track. There should be an easy way during the run to change this speed. I think of this like a treadmill but for outside (with buttons like ⬆, ⬇).

	•	Updated To-Do List (Based on recent changes):
		•	1.	Add play button during the current-run screen
		•	2.	Move the logic to start user-location-fetching only in the current-run screen + add a "fetching location..." notification with a loading spinner.
		•	3.	UI/UX improvements
		•	4.	Outdoors Testing
		•	5.	Launch?


7/28/25:

	•	GPS Flow Redesign: Changed how GPS works to be more like other running apps (Strava, Nike Run Club) with a simple loading screen instead of trying to start GPS in the background.

		• Moved GPS setup from pace selection to the running screen where it shows "Getting GPS signal..."
		• Added proper run states: looking for GPS, ready to start, running, paused, and finished
		• Shows clear loading screen while GPS connects instead of hiding it in the background
		• Added 30-second timeout so users can start even if GPS is slow

		Technical changes:
		• Fixed run_state_provider.dart to handle the new flow properly
		• Rebuilt current_run.dart to show different screens based on what the app is doing
		• Cleaned up pace_selection.dart by removing GPS code that was causing problems
		• Had to move GPS listener to build() method because of Flutter/Riverpod rules

		Bug fixes:
		• Fixed crashes when widgets close while GPS is still updating
		• Made LocationService always stop GPS properly when leaving the running screen
		• Added safety checks so the app doesn't crash when switching between screens
		• Solved timing issues between GPS updates and app navigation

		UI improvements:
		• Clear "Getting GPS..." screen so users know what's happening
		• Shows helpful hints if GPS takes longer than 15 seconds
		• Only shows running features when GPS is actually ready
		• Much clearer when the app is ready vs still setting up

		Result: GPS now works like other running apps with clear loading states and no more random crashes.

		Extras:
		• Removed unnecessary snack bar notifications during the pace selection process.
		• Allowed for more precise polyline marking by only allowing its mark to appear with the trigger of the start button (no more polyline marking when off-duty). Achieved this by adding an if statement with the run states.
		• Small UI changes


	•	Updated To-Do List for MVP:
		•	1.	[√] Move GPS logic to current-run screen with loading state
		•	2.		Organize the run modes ('predictive finish' and 'steady pace')
		•	3.		Enable captureMapScreenshot() to show map summary at the end of the run. Also show the date/time. Maybe pace splits?
		•	4.		UI/UX improvements (colors, fonts, layouts)
		•	5.		Test the app outside
		•	6.		Get ready to launch


8/2/2025:

	•	Added complete polyline route image at the end of the run and made some UI changes.

	•	Introduced a screenshot of the route at the end of the run. It's a fun feature and I want to expand on it more by saving this screenshot to the firebase data; but I think I will save this for V2, not for the MVP. Used 
	•	Used 
	•	Added the date/time of when the run was started to the run data.
	•	Played around with the UI in the Activities screen. I think I'm finding the right colors for this app.

	•	Major UI/UX Overhaul:
		•	Added new app logo to home and login screens
		•	Redesigned Activities screen with modern card layout, placeholder action buttons for later updates (info/share), and bottom navigation
		•	Improved Current Run screen with readable pace header, better stats layout, and conditional PaceBar display
		•	Improved Pace Selection with better button layout and legible goal summaries

	•	Technical Improvements:
		•	Added new Riverpod providers for map controller, locations, and readable pace state management
		•	Improved error handling and cleanup logic across widgets
		•	Refactored state management for better modularity and testability

	• 	In the next updates:
		• I am going to improve the UI of the summary dialog at the end of the run. I need to keep in mind that, in a later update, I want to copy this into the user's clipboard automatically. The purpose is for them to share it on their social media accounts.
		• I am planning to stabilize the average pace. I'm lookin into how popular apps do this. The goal is to not have jumpy data.
		• I will then start with run mode 1 ("Goal focused run").
		• Then, run mode 2 ("Stable pace mode")
		• After that, run mode 3 ("Classic Run")

	• Each of these tasks will come with their own struggles, but I think after finishing these properly I'm ready to launch the MVP.

	No real issues were encountered here.


8/3/2025:

	Run Summary Dialog Redesign: Completely rebuilt the run completion dialog with a modern card-style design and added image export functionality for social media sharing.

		• Created RunSummaryCard widget as a reusable component with dark semi-transparent background, compact map display, vertically stacked metrics, and integrated logo
		• Implemented PNG export to clipboard using RepaintBoundary for widget-to-image conversion
		• Redesigned button layout with three clear actions: Save run (preserves existing functionality), Share run (copies image to clipboard), and Discard run (with confirmation dialog)
		• Added high-quality image generation with 2x pixel ratio and base64 encoding for universal app compatibility

	• How this was achieved:
		• RepaintBoundary wrapper around exportable content to separate interactive UI from image content
		• Flutter's built-in rendering pipeline: Widget Tree → Render Tree → PNG conversion using dart:ui toImage() method
		• GlobalKey system to access render objects for image capture without external dependencies
		• Base64 encoding with data URI format for cross-platform clipboard compatibility

	• Technical challenges solved:
		• iOS simulator limitation: Clipboard shows base64 text instead of image (expected behavior, works properly on real devices)
		• State management: Proper cleanup and provider reset logic maintained across all dialog actions
		• Image quality: Implemented pixelRatio settings for Retina-quality exports
		Error handling: Added comprehensive try-catch blocks with user feedback via SnackBar notifications

	• Lessons learned:
		• Flutter's widget architecture makes complex tasks like image export very simple with the right approach
		• RepaintBoundary design pattern enables clean separation between exportable content and interactive elements
		• Built-in APIs (dart:ui, dart:convert, flutter/services) provide strong solutions without external dependencies
		• Widget-to-image conversion leverages GPU acceleration for high-performance rendering

	Result: Users can now share professional-looking run summaries directly from the app to any platform, with the dialog matching modern design standards and maintaining all existing functionality.


8/4/2025:

	UI changes:
		• During the timing selection, I switched the slider for a numeric keyboard with suggestions (30 mins, 1 hr, etc.). Previous map I made for realistic timings work better with this approach.
		• Consitent colored cards
		• Switched the running-man-marker in the pacebar for a dog, given that the new logo has a dog. I added a conditional statement; if the run is paused, the dog will stay still wagging his tail.
		• Removed motivational message display from pace bar (commented out for future haptic/sound implementation)
		• Other minor changes
	
	Later on today I will start working on the stable average pace provider(task #1), this will help me predict the end time of the run (task #2), based on the run so far.


# Pacebud Progress: 8/5/2025

## Stable Pace & Prediction System

Implemented a stable average pace provider to eliminate jumpy data and added accurate finish time predictions for goal-focused runners.

### Stable Average Pace Implementation

- Created time throttling (2-second intervals) and data smoothing (3-value moving average) to replace the jumpy average pace display. Similar to how Strava handles pace calculations for consistent UX.
- Projected Finish Time System: Added real-time predictions showing "At your current pace, you'll finish in X time" based on stable pace calculations rather than instant pace data (previous 'current pace' approach).
- Critical Unit Conversion Fix: Resolved incorrect pace calculations when using kilometers that was causing wrong predictions (showing "fast" when actually running slow). The issue was in pace selection where km distances were being incorrectly normalized to miles before calculation.

---

## How this was achieved

- Two-strategy approach: Time throttling prevents constant updates, data smoothing uses moving average of recent values.
- Created new providers for target distance/time that integrate with existing custom pace system.
- Built compact prediction display widget to fit existing UI without overflow.
- Connected stable pace provider to prediction system using string-to-seconds parsing.

---

## Conclusion

This marks the end of my first iteration of the "current pace" approach. At the beginning of the project, I thought showing the user's pace over the last few seconds (4s window) would be the best way to alert them if they were going too slow or fast. But after running again consistently, I realized that what runners truly care about is simpler: 

> “If I keep going at this pace, when will I finish my goal distance?”

That question is fully answered by the **stable average pace**, not the jumpy pace from the last few seconds. This new approach solves two essential needs:
1. It reflects how long the runner has been running, including adjustments from recent speed changes.
2. It enables an accurate **projected finish time**, which is far more actionable and goal-oriented than short-term pace feedback.

Ironically, once I returned to running regularly, the solution became clear. I had been overcomplicating things. What runners need is clarity, not noise. And to design for that, I had to take a step back and think like a runner, not just a developer.

---

## Result

The app now provides:

- **Stable, smoothed average pace calculations** using time throttling and moving averages.
- **Accurate, real-time finish time predictions** based on consistent pace.
- Full support for **both kilometers and miles**, with corrected unit conversion logic.

This makes the running experience more reliable and intuitive for goal-driven users.

---

## Next Steps

- Modify the pacebar so it reflects the gap between the **goal pace** (green zone) and the **projected finish**.
- Add run mode selection system and prepare framework for future running modes.


# Pacebud Progress Log: 8/9/2025

## More Accurate Pace Parsing and Prediction

Today I fixed a few details that were causing issues in the user experience: unit differences and some hidden conversions that were inflating times. This was necessary for the app to show what a runner expects to see.

### What Changed

- Centralized **pace parsing** in `utils/pace_utils.dart` with `parsePaceStringToSeconds`. A single place that converts "m:ss/mi" or "m:ss/km" to seconds per unit.
- Fixed **goal projection** in `projected_finish_provider.dart`:
  - Target distance is calculated in km.
  - If user runs in miles, pace is normalized to seconds/km before projecting. Result: consistent predictions in both km and miles.
- Simplified the `PaceBar`:
  - Stopped reconverting pace (it now comes in the chosen unit).
  - Added safe normalization to avoid zero divisions and weird values (icon no longer "jumps" if strange data comes in).

### Result

- Correct predicted finish time.
- Bar markers centered on desired time goal (goal is 6.1 miles in 1 hour, bar centers on 1hr)

- Set up a "run modes" view for future variants.

---

# Pacebud Progress Log: 8/10/2025

## Added Quick Start + end-to-end cleanup for Discard Run

### Problem:
- After discarding, the next run sometimes had dangling GPS info/listeners, so the map didn’t show until the second try.

### Solution:
- Full cleanup on discard: stop GPS, tracking OFF, stop/reset timer, reset run state, reset metrics/providers, clear route state, return to root.
- - Dialog handling
- `_showDiscardConfirmation(...)` now accepts `closeMainDialog` to avoid double pops. The summary dialog uses `closeMainDialog: true`; the main screen keeps the default.

---

## Persistent navigation (RootShell):
- Single bottom bar across the app with ***PageView*** (Home, Stats).
- Directional transitions (Home→Stats left-to-right, Stats→Home right-to-left).

---

## Settings:
- ***Tap-to-toggle*** between Units of Measurement (Inspired by Strava).
- Logout with confirmation.

---

## Other UI Changes:
- Redesigned the activities cards to look slimmer and modern.
- Other minor UI changes (inkWell, discard button, among other changes).

---

## Bug Fixes:
- Discard run would persist even after run started. Added a conditional statement for it to appear only when the run state is 'readyToStart'
- Added RootShell logic I forgot to put after a goal-focused run.

## Notes:
- Found a nested `MaterialApp` in `map.dart`. This can cause rendering issues. Plan: refactor the Map widget to return just `GoogleMap` (no nested `MaterialApp/Scaffold`).
- I am thinking of adding a graphic with the amount of miles/km ran during the week.
- This would be above the activties cards
- Inspired by Strava
- To achieve this I need to make the unit of measurement reflect the past runs. I have been ignoring this issue but it's catching up to me.

---

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


---

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


---

# Pacebud Progress Log: August 15-21st

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
  - Update: Improved the layout: better formatting (mm:ss under 1h) and projection text turns red when behind.

- Flutter → iOS bridge
  - `lib/services/live_activity_service.dart` — MethodChannel API: start/update/end/availability. `updateRunningActivity(...)` now also sends `goal`, `predictedFinish`, and `differenceSeconds`.
  - `lib/widgets/live_activity_provider.dart` — Listens to run state, distance, timer, and the goal/prediction providers; pushes updates to iOS. Uses `timeDifferenceSecondsProvider` (centralized) for `differenceSeconds`.
  - `lib/widgets/time_difference_provider.dart` — New provider that exposes projected vs target time difference in seconds.
  - `lib/widgets/current_run.dart` — Initializes `liveActivityProvider` in `initState()` so updates start when the run starts.

- iOS native channel (Runner target)
  - `ios/Runner/LiveActivityChannel.swift` — Starts/updates/ends the activity using ActivityKit; keeps a local copy of `PacebudActivityAttributes` (same fields as the Widget target). Parses `goal`, `predictedFinish`, and `differenceSeconds` from Flutter and passes them through.
  - `ios/Runner/AppDelegate.swift` — Registers the channel when iOS ≥ 16.2.
  - `ios/Runner/Info.plist` — Enables Live Activities and frequent updates.

---

## How it works (flow)

- Data sources: `distanceProvider`, `formattedElapsedTimeProvider`, `stableAveragePaceProvider`, `runStateProvider`.
- Extras:
  - `goal` = `targetDistanceProvider` + `formattedUnitString` + `formattedTargetTimeProvider`.
  - `predictedFinish` = `projected_finish_provider.dart` (`projectedTime`).
  - `differenceSeconds` = `time_difference_provider.dart` (positive = behind, <= 0 = on/ahead) → sent to iOS for coloring.
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
- differenceSeconds?: Int (positive = behind, drives red projection text)

---

## UI quick notes

- Lock Screen shows the main metrics; right column can show goal/predicted when present.
- Dynamic Island (expanded bottom) shows `Pace`, `goal`, and `predicted` stacked.
- Status dot: green = running, orange = paused.
- Projection text: white when on/ahead; red when behind (uses `differenceSeconds`).

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

## Other changes

- Updated GoogleService-info.plist and info.plist.

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


---

# Pacebud Progress Log: August 22-25

### - Added weekly snapshot feature using the `fl_chart` library and a template from their documentation.

### - Redesigned home screen for quick goal setup or simple run:
- User now has the ability to set a distance goal, time goal, or a distance under time goal.
- Took a lot of time to come up with a simple setup to communicate this. Real usage will dictate if my approach was right.

### - Other Changes:

Eliminated all animations with pageView and pageController to have a smoother UX.

#### Minor UI/UX changes:
- Settings in both main screens.
- User profile displayed in settings
- Stats message sisplay for new users
- Added cupertino time and distance wheel pickers for iOS.
- Fixed floating number when displayed stats were too small.
- In current run screen I disabled the slide-back option

#### What's next:
- Implement live activity simple goal status display
- Add an end-of-run screen to eventually gather more data from user and save to DB.


---

# Pacebud Progress Log: August 26-28

## Goal State Management & Run Completion System

Fixed a persistent goal issue and built a comprehensive run completion system that tracks goal outcomes and celebrates user achievements.

---

### Goal State Cleanup Fix

- **Problem**: Running goals persisted on the home screen after completing or discarding runs, causing confusion and potential data corruption
- **Root Cause**: Goal state stored in multiple providers (`customDistanceProvider`, `customPaceProvider`, `readablePaceProvider`, and temporary selection providers) wasn't being cleared when users finished their runs
- **Solution**: Created centralized `clearGoalProviders(ref)` helper function in `inline_goal_input.dart` that resets all goal-related state
- **Implementation**: Called this helper in three key places:
  - When saving a run in `RunSummaryScreen`
  - When discarding a run in `RunSummaryScreen` 
  - When discarding a run directly from `CurrentRun` (active run screen)
- **Result**: Home screen now always returns to clean "no goal" state regardless of how users exit a run, forcing fresh goal setup for each new session

---

### End-of-Run Alert Dialog Redesign

- Moved the end-of-run alert dialog to its own standalone screen for better user experience and cleaner code organization

---

### Goal Outcome Tracking System

- **Goal Progress Provider**: Created `goal_progress_provider.dart` to capture the exact time when target distance is first reached during a run
- **Integration**: Added logic in `current_run.dart` to listen for distance updates and record first-reach milestones
- **Smart Messaging**: Updated `run_summary_screen.dart` to show different messages based on goal completion:
  - **Distance+Time goals**: "You met your goal!" if first reach of target distance occurs at/before target time; otherwise "Maybe next time 😅" with either "You were short by X km/mi" (if never reached distance) or "You were off your goal by Xm Ys" (if reached distance late)
  - **Distance-only goals**: "You met your goal!" if final distance ≥ target; otherwise "Maybe next time 😅" with "You were short by X km/mi"
  - **Time-only goals**: "You met your goal!" if final elapsed time ≥ target; otherwise "Maybe next time 😅" with "You were short by Xm Ys"
- **Edge Case Handling**: System handles users stopping early or continuing past goal distance, ensuring accurate feedback regardless of when they finish

---

### Confetti Celebration System

- **Package Integration**: Added `confetti` package in `pubspec.yaml` for celebration animations
- **Controller Setup**: Implemented `ConfettiController` in `run_summary_screen.dart` with 3-second duration and explosive blast pattern
- **Automatic Triggering**: Confetti fires automatically when any goal type is met (distance+time, distance-only, or time-only)
- **Manual Celebration**: Added manual confetti button (🎉) positioned along header area for user-triggered celebrations
- **Visual Design**: Confetti widget positioned at top center with colorful particles (purple, white, red)
- **Persistent Flag System**: Prevents multiple confetti plays on screen rebuilds

---

### Technical Implementation Details

- **Main Changes**: Added confetti import and controller initialization in `RunSummaryScreen`, wrapped entire screen in `Stack` to overlay confetti and celebration button
- **Unified Logic**: Single celebration trigger covers all three goal types
- **Secondary Improvements**:
  - **Distance-only goals**: confetti fires when final distance ≥ target distance
  - **Time-only goals**: confetti fires when final elapsed time ≥ target time
  - **Distance+Time goals**: confetti fires when target distance reached at/before target time
- **Button Styling**: Celebration button styled with red accent and emoji icon for better visual appeal

---

### Other Improvements

- Added red-when-above logic to finish time projection in run screen
- Fixed colliding logic in home screen 'start run' button

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
- Live activities loading bar for user's goal
- Sound effects for goal achievements
- Save user's goal to the database.
- Save whether the user met their goal or not.
- Modify the weekly line chart to handle month and year.
- Maybe: Add precipitation % chances in home screen (there's a lot of dead space that I need to fill according to my friend Tristan). I'll see how viable it is to add this; most likely easy.
- Maybe: split average pace data during run
    - Split average pace line chart inside run info.
- Maybe: calories and other common data inside the run info.

---

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

# Pacebud Progress Log: August 31st

## Google Maps Authentication Problem

### What Was Happening
My app was showing a blank map with just a blue dot (no streets, no details). Users could see their location but the map tiles weren't loading.

For a long time I've been wondering how to launch this if I am using .env files. I now discovered that **client-side API keys (Google Maps, Firebase Web) are not actually secrets**. I had been treating them like passwords, hiding them in `.env` files and thinking this made my app secure.

The real security comes from **restrictions set in the Google Cloud Console**; things like Bundle ID restrictions, package name restrictions, and SHA fingerprint requirements prevent other apps from using the keys, even if they're visible in code.

In `AppDelegate.swift`: I was passing a literal string `"GOOGLE_MAPS_API_KEY"` instead of the actual API key. Google Maps couldn't authenticate, so it showed blank tiles.

Steps I took:
1. Put the real API key in `Info.plist` 
2. Read it from there in `AppDelegate.swift` instead of using a literal
3. Ensure the key is restricted to my Bundle ID (`com.orzan.pacerunner`) in Google Cloud

### Why APIs Are Now "Exposed" (And Why It's Safe)
I moved from using `.env` files to hardcoding the keys directly in the appropriate platform files:
- **iOS**: `Info.plist` + `AppDelegate.swift`
- **Android**: `AndroidManifest.xml` 
- **Firebase**: `firebase_options.dart`

Exposing these feels wrong at first, but it's actually the standard approach. The keys are protected by:
- **Bundle ID restrictions** (iOS)
- **Package name + SHA fingerprint restrictions** (Android)  
- **Billing requirements** (Google Cloud)

### How security is matained
- **Google Maps iOS key**: Only works with apps having the right Bundle ID.
- **Google Maps Android key**: Only works with my package + specific SHA fingerprints
- **Firebase keys**: Restricted to the same identifiers
- **Billing**: My Google Cloud project has billing enabled, so Google knows who to charge

### Current Issues (Non-crucial)
- **UI unresponsiveness warnings**: LocationManager calls on main thread
  - *Impact*: Minor performance warning, doesn't affect functionality
  - *Fix*: Migrate to `locationManagerDidChangeAuthorization` callback
- **CoreData warnings**: Google Maps SDK internal warnings
  - *Impact*: None - SDK internal issue
- **Multiple CCTClearcutUploader instances**: SDK initialization warning
  - *Impact*: Minor battery performance, doesn't affect functionality

According to an AI model, these are mostly noise from the iOS simulator and SDK internals. They don't break the app or compromise security.

### Summary
- **Problem**: Hardcoded literal in iOS code prevented Google Maps authentication
- **Solution**: Proper key injection via `Info.plist` + correct Google Cloud restrictions
- **Result**: Map loads correctly, all APIs are secure, app ready for production
- **Security**: Keys are "exposed" but properly restricted - this is the standard approach


### What's Next
- Fix loading times, map loading has been taking forever in physical device

---

# Pacebud Progress Log: September 1st, 2025

## Map loading times fix

In `map.dart`: 
- `_primeInitialLocation` - render map immediately without internal spinner or nested MaterialApp/Scaffold

In `gps_status_provider.dart`:
- Consider null as weak GPS status

In `current_run.dart`:
- First-fix shortcut: remove bottom loader as soon as any location arrives (don't wait for 30s timeout)
- GPS status banners subtle: "Weak GPS signal" while weak, "GPS signal acquired" momentary when improving
- Show map always (no intermediate loading screen)
- Transition to readyToStart when GPS stops "acquiring" (even if weak)

In `location_service.dart`:
- For faster initial acquisition at rest, use high accuracy and distanceFilter 0 (emits even when not moving)
- Then, when starting the run, bump to Navigation + 5m in `resumeLocationTracking()`

In `home_screen.dart`:
- Pre-warm GPS as soon as Home is shown (non-blocking)

In `gps_status_provider.dart`:
- Flag for testing UI in weak GPS signal


### Other
- Fixed key-value pair for live activity in info.plist
- Added 'shake' animation because I was worried the UI wasn't intuitive enough. The shake widgets are wrapped around the distance and time input segments using AnimatedBuilder to apply Transform.translate, creating a subtle luring effect that guides users to complete their goal selection.
- Added showNoMovementDialog() to restrict run savings to be over 0.01 km/mi.

### What's Next
- Launch for real user testing
- Add sound alerts
- Add split pace

---

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
- Fix issue: When run is not active and app is closed, we keep tracking user's location (have blue GPS indicator on). Hours after completing the run/not being active.
- Make sure to save in the database whether the user reached their goal or not, how long it took them, or how far where they off completing it 
- Launch for real user testing
- Add split pace stats + charts

---

# Pacebud Progress Log: September 15-16th, 2025

## Sign in with apple ID setup

I tried uploading this app for apple review and they told me I needed to:
- Update the screenshots so that they don't have the "debug" banner flutter provides
- Add another sign-in method (Guideline 4.8 - Login Services)
- Add a test sign-in method for them to test the app (Guideline 2.1)

1. **Dependencies**:
   - `sign_in_with_apple: ^6.1.0`
   - `crypto: ^3.0.3`

2. **Apple Developer Console**:
   - Enabled "Sign in with Apple" capability for App ID
   - Created Services ID `com.orzan.pacebud.service` (not used in final config)
   - Generated .p8 private key with Key ID
   - Configured website URLs

3. **Firebase Console**:
   - Enabled Apple as sign-in provider
   - Learned that "Services ID" field should use the main App ID (`com.orzan.pacerunner`), not the separate Services ID
   - Configured with Apple Team ID, Key ID, and private key

4. **iOS Configuration**:
   - Added `com.apple.developer.applesignin` entitlement to `Runner.entitlements`
   - iOS deployment target already ≥ 13.0 (required for Sign in with Apple)

5. **Code Implementation**:
   - Secure nonce generation (SHA-256 hashing)
   - Native Apple ID credential request with email and fullName scopes
   - Firebase OAuth credential creation with `apple.com` provider
   - Error handling for account conflicts and credential issues
   - Display name updates from Apple ID information
   - Custom button (matches Google Sign In)

### Lesson Learned:
- For iOS native, Firebase needs the main App ID in the field "services ID", not a separate Services ID. The Firebase documentation is confusing in this matter; it says "Services ID (not required for Apple)" but then requires the App ID in that field for token validation.

## Location Listener

Added mechanism to detect when the user leaves the app to stop tracking automatically.

- Used WidgetsBindingObserver with runStateProvider according to the existing flow:
1. tracking begins at HomeScreen.initState() for pre-warming
2. tracking stops at CurrentRun.dispose()

- Location trcking stayed active because there was no listener for the app's lifecycle

- `RunState.running` and `RunState.paused` are considered active sessions

**Code Implementation:**
```dart
final isRunning = runState == RunState.running || runState == RunState.paused;

if (!isRunning && LocationService.isInitialized) {
  await LocationService.stopLocationTracking();
}
```

## GPS Status Spam Fix (Logout)

Fixed issue where LocationService would spam GPS status update errors after user logout.

**Problem:** When user logs out, RootShell gets disposed but LocationService continues trying to update GPS status with an invalid WidgetRef, causing console spam:
```
flutter: LocationService: GPS status update failed (widget disposed): Bad state: Cannot use "ref" after the widget was disposed.
```

**Solution:**
1. LocationService.dispose() called when user logs out
2. When ref becomes invalid, clear it immediately to prevent spam
3. If ref is cleared while tracking, automatically stop LocationService
4. **Protected all GPS status update methods** with ref validation and cleanup

## Goal Achievement Data

Added goal achievement tracking and data persistence to Firebase for all three goal types.

**Goal Types Supported:**
1. **Time Only Goal** (e.g., "Run for 30 minutes")
2. **Distance Only Goal** (e.g., "Run 5km") 
3. **Distance Under Time Goal** (e.g., "Run 5km in under 30 minutes")

**Data Saved to Firebase:**
- `goalAchieved`: Boolean indicating if the user met their objective
- `goalCompletionTimeSeconds`: Time when the goal was reached (null if not achieved)
- `totalRunTimeSeconds`: Total duration of the entire run

**Implementation Details:**
- Reuses existing confetti logic to determine goal achievement
- For distance-based goals: saves time when target distance was first reached
- For time-only goals: saves target time as completion time when achieved
- Captures both objective completion time AND total run duration for comprehensive analytics

**Example Scenario:**
```
Goal: 5km in under 30 minutes
Reality: User runs 6km in 32 minutes, reaching 5km at 25 minutes

Saved Data:
- goalAchieved: true (25min < 30min)
- goalCompletionTimeSeconds: 1500 (25 minutes)
- totalRunTimeSeconds: 1920 (32 minutes)
```

## Dialogs
### 1. Added/improved alert dialogs for:
- About Pacebud: Included "send feedback button" with LSApplicationQueriesSchemes (info.plist)
- Data deletion
- User log out
- First time usage location instructions (maybeShowFirstLaunchPermissionGuide)
- First time usage goal setup instructions (maybeShowFirstLaunchPermissionGuide) (asks right before going to run screen)
- No location warning --> Go to settings

### 2. Centralized settings sheet into its own component

### What's Next
- Launch for real user testing.
- Add more stats (split pace stats + charts, elevation, elevation gain, cadence, etc.)


---

# Pacebud Progress Log: September 15-16th, 2025

## Account Deletion Feature - Apple App Store Compliance

Implemented comprehensive account deletion functionality to meet Apple App Store Review Guidelines 5.1.1(v), which requires "apps that support account creation to also allow users to delete their accounts".

### **Features**

**1. Account Deletion UI:**
- Added "Delete Account" option in Settings → Account settings
- Easy to find and access (Apple requirement)
- Clear visual hierarchy with warning indicators

**2. Complete Data Deletion:**
- Deletes user's Firebase Auth account
- Removes all user data from Firestore:
  - All running activities and stats
  - User profile and settings
  - Complete data cleanup (not just deactivation)

**3. User Safety & Transparency:**
- Clear confirmation dialog explaining what will be deleted
- "You will lose:" section listing specific data types
- "This action cannot be undone" warning
- Multiple confirmation steps to prevent accidental deletion

**4. Security Compliance:**
- Handles Firebase re-authentication requirements
- When re-auth needed, forces user to sign out and sign in again
- No bypass options for security requirements

**5. Error Handling:**
- Graceful handling of network failures
- Clear error messages for users
- Loading indicators during deletion process
- Automatic navigation to login after successful deletion

### **Apple App Store Compliance:**

**Easy to find**: Located in Settings → Account settings  
**Complete deletion**: Removes account + all associated data  
**Clear process**: User understands exactly what happens  
**No workarounds**: Cannot just deactivate or disable  
**Proper confirmation**: Multiple steps prevent accidents  
**Security compliant**: Respects Firebase re-authentication  

## UI/UX changes:
- "Help" button in goal input"
- Change wording in live activity ("under" instead of "in")
- Improved the onboarding to include the "About Pacebud" dialog.
- Added expandable "Account settings" section in Settings
- Reorganized Settings UI with better visual hierarchy
- Streamlined re-authentication flow with single "Sign Out" option

## What's Next
- Launch for real user testing and feedback.
- Add more stats (split pace stats + charts, elevation, elevation gain, cadence, etc.)