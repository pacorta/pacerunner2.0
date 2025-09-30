# Pacebud Progress Log: Sept 24th, 2025

## App is now live on the AppStore!

## Fixed Bugs:
- Live activity would not stop if user started a run and ran less than 0.1 mi/km. 
  - Solution: stop it when pressing 'discard' on the "no movement detected" warning.


## User Feedback:

### Bugs:
- Goal is set to 8.0mi under 1h25mins, we finish race at 8.0 mi in 1h21mi41s. The app thinks user didnt reach thier goal because they were “short by 0.0 mi”.
- Save the runs just when the ends the run, not when they confirm after. User tends to exit the app fast.
- Run completed screen (or any other screen) can be enlarged if the user has the text of their phone larger, resulting in not seeing the 'ok button immediatly. Given that we currently save the run when they press this button, if they leave without pressing this, their run will not be saved.

### Improve soon:
- Save the map photo in the user’s data. If user has no map, don’t show anything.
- Add the projected finish time even when the user doesn’t put a goal time.
- Make the weekly data also be about the last month, and last 10 weeks. Every dot should be a quantity of miles/km.
- Add medals for completing the goal.
- Make it easier to share on social media (maybe with appinio_social_share 0.3.2).
- The user should leave the “end run” button pressed for about a second to make sure they intended to finish the run (or add an alert to confirm).

### Nice to have:
- Add a streak by week like Hevy/Strava.
- Add a graph that shows how your endurance/speed has improved in the previous runs.
- Additional: Add a function to plan ahead by calculating the distance of a route (with google maps calculate distance feature).
- Add the split pace alerts option.
- If we eventually add social media, a user should be able to challenge their friends for time/distance/pace runs and bet trophies or something.

---
#### (For earlier logs, see `PAST-LOGS.md`)