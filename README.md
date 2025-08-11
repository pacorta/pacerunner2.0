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

## Notes:
- Found a nested `MaterialApp` in `map.dart`. This can cause rendering issues. Plan: refactor the Map widget to return just `GoogleMap` (no nested `MaterialApp/Scaffold`).
- I am thinking of adding a graphic with the amount of miles/km ran during the week.
- This would be above the activties cards
- Inspired by Strava
- To achieve this I need to make the unit of measurement reflect the past runs. I have been ignoring this issue but it's catching up to me.

(For earlier logs, see `PAST-LOGS.md`)