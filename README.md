# Pacebud Progress Log: Sept 24th - Oct 10th, 2025

### App is now live on the AppStore!
- Update 1.1.0(1):

## New Features:
- **12-Week Progress View**
  - Toggle between weekly breakdown and 12-week overview with segmented control.
  - Tap weeks in 12-week view to browse history, then drill down to daily stats in week mode.
  - Tap individual days to see single-day performance with persistent vertical line indicator.
  - Dynamic titles: "This week", "Sep 22 - Sep 28, 2025", "Today", "Wednesday, Sep 24".
  - Discrete clear button (×) to return from day view to week totals.
  - Implementation:
    - Created `stats_view_mode_provider.dart` for toggle state (defaults to Last 12 Weeks).
    - Built `stats_segmented_control.dart` with mode switching.
    - Added `selected_week_provider.dart` and `selected_day_provider.dart` for selection state (tried to follow DRY pattern).
    - Extended `weekly_line_chart.dart` to support both 7-day and 12-week modes with month labels (JUL, AUG, SEP, OCT).
    - Centralized date utilities in `date_utils.dart` (week ranges, month/day name constants).
    - Refactored `weekly_snapshot.dart` to handle both modes with individual week/day drill-down.
    - Chart shows 3 horizontal grid lines (0, middle, max) for minimal clutter.
    - Activity list below chart filters to show runs from selected week/day (Week mode only).

- **Projected finish time now shows for distance-only goals**
  - Users can now see their projected finish time based on current pace even when they only set a distance goal (without a time target).
  - Implementation:
    - Modified `projected_finish_provider.dart` to calculate projections with just distance (removed requirement for target time).
    - Updated `prediction_display.dart` to show projection in white for distance-only goals (no color coding since there's no time to compare against).
    - Updated `live_activity_provider.dart` to display projection for distance-only goals on iOS Live Activities.
    - Fixed `current_run.dart` to show `PredictionDisplay` when only distance is set.
  - Behavior: Distance+time goals still show color coding (red when behind, white/green when on track), while distance-only goals always display in white.

- **Manual Activity Entry**
  - Added ability to manually enter running activities
  - Implementation:
    - Added "+" button to Activities screen AppBar for easy access.
    - Created `AddManualActivityModal`.
    - Built custom Cupertino pickers for all input types:
      - **Date/Time**: "Today at 3:56 PM" format for current day, "Tue Oct 7 at 3:56 PM" for other days.
      - **Duration**: HH:MM:SS format with range 00:00:00 - 99:59:59.
      - **Distance**: 0.0-999.9 with 1 decimal, integrated mi/km unit selection in picker wheel.
      - **Pace**: MM:SS format with range 0:00-59:59, integrated /mi or /km unit selection in picker wheel.
    - **Auto-calculation Logic**: If exactly 2 of 3 fields (Time, Distance, Pace) are filled, automatically calculates the third. If all 3 fields have values and user edits one, recalculates the field that was calculated automatically most recently.
    - **Unit Synchronization**: Distance and Pace units are always synchronized (mi <-> km) without converting numerical values.
    - **Smart Save Button**: Gray and disabled when data incomplete, purple and enabled when all fields complete.
    - **Persistence**: Uses existing `RunSaveService` with `isManual: true` field to distinguish manual from GPS runs.

- **Activities Graph Sharing**
  - Users can now share their weekly/12-week stats graph as a PNG image to social media
  - Implementation:
    - Unified clipboard logic into reusable `ClipboardService` (DRY principle) - removed duplication from `running_stats.dart` and `run_summary_screen.dart`.
    - Added discrete share button (iOS share icon) next to graph title.
    - Export uses brief "flicker" effect to apply export styling without affecting normal UI.
    - Exported image features:
      - Semi-transparent white background and 18px rounded corners.
      - 20px internal padding (so that graph labels stay visible).
      - Pacebud horizontal logo
      - Buttons and controls hidden during capture to keep image clean.
    - Uses `RepaintBoundary`, `GlobalKey`, and `ValueNotifier` for selective widget capture at 3x pixel ratio.
    - Comments:
      - Not a big fan of the "flicker" (28ms) but it's the only solution I can think of at the moment. Will probably improve when I add the social media sharing modal.

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
    - Added `deleteRun(docId)` method to `RunSaveService` for modular deletion.
    - Added loading dialog "Saving run..." so user sees feedback (no frozen screen).
    - Implemented local backup with `SharedPreferences` if Firestore fails or user is offline.
    - Auto-sync pending runs on app startup via `AuthWrapper` (2s delay for Firebase init).
    - Show orange snackbar if save fails: "Run saved locally. Will sync when online."

- Goal distance validation was too strict (1.0 minimum) and didn't prevent navigation on invalid input.
  - Solution:
    - Lowered hard minimum from 1.0 to 0.1 mi/km for flexibility.
    - Added soft warning dialog for distances < 1.0, allowing users to proceed if desired.
    - Made `setGoalFromTempSelections` async and return bool to prevent navigation on validation failure.
    - Reused dialog pattern from existing code for consistency (DRY principle).

- Goal setup dialog was duplicated in two places (onboarding and help button), causing inconsistency.
  - Solution:
    - Created `showGoalSetupDialog()` as single source of truth in `inline_goal_input.dart`.
    - Removed duplicate dialog from `home_screen.dart` (~180 lines).
    - Standardized to use Icon instead of emoji for consistency.
    - Both onboarding and help button now call the same function.

- Unit of measurement always defaulted to km on app restart.
  - Solution:
    - Converted `distanceUnitProvider` from simple `StateProvider` to `StateNotifier` with automatic persistence.
    - Implemented `SharedPreferences` storage with `_loadPreference()` on init and `setUnit()` for saves.
    - Updated `settings_sheet.dart` and `inline_goal_input.dart` to use async `setUnit()` method.



## User Feedback:

### Bugs:
- Run completed screen (or any other screen) can be enlarged if the user has the text of their phone larger, resulting in not seeing the 'ok button immediatly. Given that we currently save the run when they press this button, if they leave without pressing this, their run will not be saved.


### Improve soon (In order of importance):
1) Save the map photo in the user's data. If user has no map, don't show anything. Make it optional to share it on user's story (Include map? Y/N)
2) Add medals/rewards for completing a goal. Then by completing their longest ever run/ fastest time in the 5k, 10k 1/2mara, or marathon.
3) Make it easier to share on social media (maybe with appinio_social_share 0.3.2).
4) The user should leave the "end run" button pressed for about a second to make sure they intended to finish the run (or add an alert to confirm).
5) Improve more DRY occassions.

### Would be nice to have:
- Add a streak by week like Hevy/Strava.
- Add a graph that shows how your endurance/speed has improved in the previous runs.
- Additional: Add a function to plan ahead by calculating the distance of a route (with google maps calculate distance feature).
- Add the split pace alerts option.
- If we eventually add social media, a user should be able to challenge their friends for time/distance/pace runs and bet trophies or something.
- Send notifications after periods of inactivity (ex. "Those miles aren't gonna run themselves")
- Activities:
  - Default view of last 12 weeks is this week and that's ok. But let's add an easter egg. By tapping "last 12 weeks" (when it's already selected), we can show the total amount of data for the last 12 weeks accumulated.
  - Add a "share button" to save on camera roll or "copy to clipboard" for saving the whole rectangle of information along with the graph.

---
#### (For earlier logs, see `PAST-LOGS.md`)