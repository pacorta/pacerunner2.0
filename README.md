#PaceRunner Progress

##7/12/24

It can now detect the device’s current location and its speed (in m/s).

##7/13/24

It can detect the device’s current location, but it’s a little buggy. I need to improve the accuracy.
Detects speed (in m/s). Need to make it into mph.
It can successfully run on an iPhone (For new devices, go to settings> security & privacy> General Tab> “iproxy was blocked” -> Clicked the Open Anyway button to allow iproxy to run.)
It adds polyline points to mark the route the user has taken during the session.

##7/18/2024

The app can now access the speed information from the Map widget in the currentRun widget; this was achieved by using the Riverpod package — a state management solution for Flutter.
	This will be useful in later stages when wanting to display the travel statistics in other parts of the app.

##7/19/2024

The app displays the speed in mph instead of the default m/s.

##8/7/2024

The app now calculates the user’s traveled distance from the moment they press “start running” and the total distance (so far) is displayed during the run. The total distance will be displayed on a pop up screen for run stats after the user presses “end run”.

We've moved from local state (_totalDistance) to global state management (distanceProvider).
Tracking control has shifted from explicit methods to a state-driven approach using trackingProvider.
The app now reacts to state changes, making it more flexible and easier to manage.



###To-Do List
- [ ] Make a summary page that includes the following (after checking the data you already have below): 
    - [ ] Total trip’s polyline representation
    - [ ] Average Pace
    - [x] Total Distance
    - [x] Time elapsed
- [ ] Main goal: add a “progress bar” that checks the speed of the runner compared to an ideal speed:   [—————(actual pace (too slow))——————————(best pace)————(actual pace (too fast))——————]
- [ ] Remove the user’s ability to go back to the home screen by clicking the “back” arrow button or sliding back because this can lead to “data loss error”. 



##8/12/2024

The app lets the user choose between miles and km in the Home Screen, which will be reflected in the ‘Current Run’ screen.
App can check the user’s pace (pace 1 = hr/distance). This is good, but I still need the pace (pace 2 = distance/hr).
I’m thinking of using pace1 for the functionality of the pacerunner because pace1 tells me how long it’ll take the user to complete 1 mile. Pace2 should be the one the user sees because I notice other running apps use this one and users are already used to this.
I found that GoogleMapsController has a function called “captureMapScreenshot()” which would allow me to get a screenshot of the overall path traveled by the user, hopefully the polyline also shows.

###To-Do List
- [ ] Make a summary page that includes the following (after checking the data you already have below): 
    - [ ] Total trip’s polyline representation (maybe using captureMapScreenshot() )
    - [x] Pace1
    - [ ] Pace2
    - [x] Total Distance
    - [x] Time elapsed
- [ ] Main goal: add a “progress bar” that checks the speed of the runner compared to an ideal speed:   [—————(actual pace (too slow))——————————(best pace)————(actual pace (too fast))——————]

Resources:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
