# Pacebud Progress Log: August 31st

## Google Maps Authentication Problem

### What Was Happening
My app was showing a blank map with just a blue dot (no streets, no details). Users could see their location but the map tiles weren't loading.

For a long time I've been wondering how to launch this if I am using .env files. I now discovered that **client-side API keys (Google Maps, Firebase Web) are not actually secrets**. I had been treating them like passwords, hiding them in `.env` files and thinking this made my app secure.

The real security comes from **restrictions set in the Google Cloud Console**; things like Bundle ID restrictions, package name restrictions, and SHA fingerprint requirements prevent other apps from using the keys, even if they're visible in code.

In `AppDelegate.swift`: I was passing a literal string `"GOOGLE_MAPS_API_KEY"` instead of the actual API key. Google Maps couldn't authenticate, so it showed blank tiles.

Steps I took:
1. Put the real API key in `Info.plist` 
2. Read it from there in `AppDelegate.swift` instead of using a literal
3. Ensure the key is restricted to my Bundle ID (`com.orzan.pacerunner`) in Google Cloud

### Why APIs Are Now "Exposed" (And Why It's Safe)
I moved from using `.env` files to hardcoding the keys directly in the appropriate platform files:
- **iOS**: `Info.plist` + `AppDelegate.swift`
- **Android**: `AndroidManifest.xml` 
- **Firebase**: `firebase_options.dart`

Exposing these feels wrong at first, but it's actually the standard approach. The keys are protected by:
- **Bundle ID restrictions** (iOS)
- **Package name + SHA fingerprint restrictions** (Android)  
- **Billing requirements** (Google Cloud)

### How security is matained
- **Google Maps iOS key**: Only works with apps having the right Bundle ID.
- **Google Maps Android key**: Only works with my package + specific SHA fingerprints
- **Firebase keys**: Restricted to the same identifiers
- **Billing**: My Google Cloud project has billing enabled, so Google knows who to charge

### Current Issues (Non-crucial)
- **UI unresponsiveness warnings**: LocationManager calls on main thread
  - *Impact*: Minor performance warning, doesn't affect functionality
  - *Fix*: Migrate to `locationManagerDidChangeAuthorization` callback
- **CoreData warnings**: Google Maps SDK internal warnings
  - *Impact*: None - SDK internal issue
- **Multiple CCTClearcutUploader instances**: SDK initialization warning
  - *Impact*: Minor battery performance, doesn't affect functionality

According to an AI model, these are mostly noise from the iOS simulator and SDK internals. They don't break the app or compromise security.

### Summary
- **Problem**: Hardcoded literal in iOS code prevented Google Maps authentication
- **Solution**: Proper key injection via `Info.plist` + correct Google Cloud restrictions
- **Result**: Map loads correctly, all APIs are secure, app ready for production
- **Security**: Keys are "exposed" but properly restricted - this is the standard approach


### What's Next
- Fix loading times, map loading has been taking forever in physical device
- 
---
#### (For earlier logs, see `PAST-LOGS.md`)