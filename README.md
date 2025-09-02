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
Fixed key-value pair for live activity in info.plist

### What's Next
- Sound alerts
- Split pace
- Fix intentional user breaks (saving a very short run)
- Launch ??

---
#### (For earlier logs, see `PAST-LOGS.md`)