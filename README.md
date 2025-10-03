# Pacebud Progress Log: Sept 24-29th, 2025

## App is now live on the AppStore!

## Fixed Bugs:
- Live activity would not stop if user started a run and ran less than 0.1 mi/km. 
  - Solution: stop it when pressing 'discard' on the "no movement detected" warning.

- Distance+time and distance-only goals could show "short by 0.00" or save goalAchieved=false when finishing right at the target distance. UI showed a rounded distance (ex. 8.0 mi) while the threshold crossing used raw precision, so the "first reach" timestamp could be missing.
  - Solution:
    - Use raw distance internally (and pass it to summary) for consistent evaluation.
    - Apply epsilon (0.01 mi / 0.02 km) to treat edge cases as reached.
    - If the "first reach" timestamp is missing but distance is effectively reached, fall back to total run time for goal evaluation and to save goalCompletionTimeSeconds.
    - For distance-only headers, use the same epsilon and clamp tiny remainders (< epsilon) to 0.00 so the UI doesn’t show misleading "short by 0.00".
    - Presentational only: format distance in the card to 2 decimals; evaluation keeps full precision.

- Some users don't wait around to press "Done", which is when we save the run.
  - Solution: 
    - Moved save flow from "Done" button to "FINISH" button so runs persist immediately.
    - Created `RunSaveService` to modularly build and persist run data.
    - Modified `saveRunData()` to return Firestore doc ID for tracking.
    - Pass saved doc ID to `RunSummaryScreen` so "Discard run" can delete it from database.
    - Added `deleteRun(docId)` method to `RunSaveService` for modular deletion

- Goal distance validation was too strict (1.0 minimum) and didn't prevent navigation on invalid input.
  - Solution:
    - Lowered hard minimum from 1.0 to 0.1 mi/km for flexibility.
    - Added soft warning dialog for distances < 1.0, allowing users to proceed if desired.
    - Made `setGoalFromTempSelections` async and return bool to prevent navigation on validation failure.
    - Reused dialog pattern from existing code for consistency (DRY principle).

## New Features:
- **Projected finish time now shows for distance-only goals**
  - Users can now see their projected finish time based on current pace even when they only set a distance goal (without a time target).
  - Implementation:
    - Modified `projected_finish_provider.dart` to calculate projections with just distance (removed requirement for target time).
    - Updated `prediction_display.dart` to show projection in white for distance-only goals (no color coding since there's no time to compare against).
    - Updated `live_activity_provider.dart` to display projection for distance-only goals on iOS Live Activities.
    - Fixed `current_run.dart` to show `PredictionDisplay` when only distance is set.
  - Behavior: Distance+time goals still show color coding (red when behind, white/green when on track), while distance-only goals always display in white.

## User Feedback:

### Bugs:
- Run completed screen (or any other screen) can be enlarged if the user has the text of their phone larger, resulting in not seeing the 'ok button immediatly. Given that we currently save the run when they press this button, if they leave without pressing this, their run will not be saved.

### Improve soon (In order of importance):
1) Save the map photo in the user's data. If user has no map, don't show anything. Make it optional to share it on user's story (Include map? Y/N)
2) Make the weekly data also be about the last month, and last 10 weeks. Every dot should be a quantity of miles/km.
3) Add medals/rewards for completing a goal. Then by completing their longest ever run/ fastest time in the 5k, 10k 1/2mara, or marathon.
4) Make it easier to share on social media (maybe with appinio_social_share 0.3.2).
5) The user should leave the "end run" button pressed for about a second to make sure they intended to finish the run (or add an alert to confirm).
6) Improve DRY occassions.

### Would be nice to have:
- Add a streak by week like Hevy/Strava.
- Add a graph that shows how your endurance/speed has improved in the previous runs.
- Additional: Add a function to plan ahead by calculating the distance of a route (with google maps calculate distance feature).
- Add the split pace alerts option.
- If we eventually add social media, a user should be able to challenge their friends for time/distance/pace runs and bet trophies or something.

---
#### (For earlier logs, see `PAST-LOGS.md`)