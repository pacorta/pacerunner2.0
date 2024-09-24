PaceRunner Progress

7/12/24

	•	The app can now detect the device’s current location and speed (in m/s).

7/13/24

	•	The app detects the device’s current location, but accuracy needs improvement (still buggy).
	•	Detects speed in m/s, but I need to convert this to mph.
	•	Successfully runs on an iPhone.
	•	Note for new devices: Go to Settings > Security & Privacy > General Tab, click “iproxy was blocked,” then click Open Anyway to allow iproxy to run.
	•	Adds polyline points to mark the route taken during the session.

7/18/24

	•	The app now accesses speed information from the Map widget in the currentRun widget.
This was achieved using the Riverpod package for state management, which will be useful for displaying travel statistics elsewhere in the app.

7/19/24

	•	Speed is now displayed in mph instead of m/s.

8/7/24

	•	The app calculates the user’s traveled distance from when they press Start Running, displaying the total distance during the run.
	•	After pressing End Run, a pop-up shows the total distance in the run stats.
	•	Transitioned from local state (_totalDistance) to global state management (distanceProvider).
	•	Tracking control has shifted to a state-driven approach using trackingProvider.
	•	The app now reacts to state changes, making it more flexible and easier to manage.

To-Do List

	•	Create a summary page that includes the following:
	•	Total trip’s polyline representation
	•	Average Pace
	•	Total Distance
	•	Time Elapsed
	•	Main Goal: Add a progress bar that compares the user’s actual speed to an ideal speed:
	•	[—————(Actual Pace: Too Slow)————————(Best Pace)————(Actual Pace: Too Fast)—————]
	•	Remove the ability to go back to the home screen using the back arrow or sliding back, as this can cause data loss.

8/12/24

	•	Added the ability to choose between miles and kilometers on the Home Screen. This setting is reflected on the Current Run screen.
	•	Added a check for user pace:
	•	Pace1 = hr/distance: This is useful for knowing how long it takes the user to complete one mile.
	•	Pace2 = distance/hr: This should be shown to the user, as it’s more common in other running apps.
	•	Found that the GoogleMapsController function captureMapScreenshot() could be used to capture a screenshot of the overall path traveled by the user, ideally with the polyline displayed.

To-Do List

	•	Summary page to include:
	•	Total trip’s polyline representation (possibly using captureMapScreenshot())
	•	Pace1
	•	Pace2
	•	Total Distance
	•	Time Elapsed
	•	Main Goal: Add a progress bar to compare the runner’s speed to an ideal speed.

Resources:

	•	[Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
	•	[Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the [online documentation](https://docs.flutter.dev/), which offers tutorials, samples, guidance on mobile development, and a full API reference.


9/24/2024

	•	Focused on making the PaceBar work properly. Key changes include:
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
