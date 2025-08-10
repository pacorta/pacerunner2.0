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