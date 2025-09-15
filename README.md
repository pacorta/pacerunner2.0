# Pacebud Progress Log: September 15th, 2025

## Sign in with apple ID setup

I tried uploading this app for apple review and they told me I needed to:
- Update the screenshots so that they don't have the "debug" banner flutter provides
- Add another sign-in method (Guideline 4.8 - Login Services)
- Add a test sign-in method for them to test the app (Guideline 2.1)

1. **Dependencies**:
   - `sign_in_with_apple: ^6.1.0`
   - `crypto: ^3.0.3`

2. **Apple Developer Console**:
   - Enabled "Sign in with Apple" capability for App ID
   - Created Services ID `com.orzan.pacebud.service` (not used in final config)
   - Generated .p8 private key with Key ID
   - Configured website URLs

3. **Firebase Console**:
   - Enabled Apple as sign-in provider
   - Learned that "Services ID" field should use the main App ID (`com.orzan.pacerunner`), not the separate Services ID
   - Configured with Apple Team ID, Key ID, and private key

4. **iOS Configuration**:
   - Added `com.apple.developer.applesignin` entitlement to `Runner.entitlements`
   - iOS deployment target already ≥ 13.0 (required for Sign in with Apple)

5. **Code Implementation**:
   - Secure nonce generation (SHA-256 hashing)
   - Native Apple ID credential request with email and fullName scopes
   - Firebase OAuth credential creation with `apple.com` provider
   - Error handling for account conflicts and credential issues
   - Display name updates from Apple ID information
   - Custom button (matches Google Sign In)

### Lesson Learned:
- For iOS native, Firebase needs the main App ID in the field "services ID", not a separate Services ID. The Firebase documentation is confusing in this matter; it says "Services ID (not required for Apple)" but then requires the App ID in that field for token validation.

### What's Next
- Fix issue: when after not on a run, app keeps tracking user's location (have blue GPS indicator on). Hours after completing the run/not being active.
- Make sure to save in the database whether the user reached their goal or not, how long it took them, or how far where they off completing it.
- Add sound alerts.
- Add split pace stats + charts.
- Launch for real user testing.

---
#### (For earlier logs, see `PAST-LOGS.md`)