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