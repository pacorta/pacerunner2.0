PaceRunner Progress 🏃

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