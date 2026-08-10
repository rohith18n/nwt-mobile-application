# ODM & iOS Target Changes (README)

## What Was Done

### 1. ODM (On-Device Conversion Measurement) for Google Ads
- **Flutter:** Upgraded `firebase_analytics` to ^12.0.0; added `crypto` for SHA256.
- **Logic:** Normalize email/phone per Google rules → SHA256 (32 raw bytes) → base64. Dart calls `FirebaseAnalytics.initiateOnDeviceConversionMeasurementWithHashedPhoneNumber(base64)` or `WithHashedEmailAddress(base64)`. Phone (E.164) preferred, then email.
- **Files:** `lib/utils/odm_conversion_utils.dart` (normalize + `sha256Base64ForOdm`), `lib/services/analytics/analytics_service.dart`, `lib/services/auth/auth_flow.dart` (call after `identifyUser`).
- **iOS:** No ODM code in AppDelegate; all via Flutter firebase_analytics plugin.

### 2. iOS Deployment Target: 13 → 15
- **Reason:** firebase_analytics 12.x iOS pod requires minimum iOS 15.0.
- **Changes:**
  - `ios/Podfile`: `platform :ios, '15.0'`
  - `ios/Runner.xcodeproj/project.pbxproj`: `IPHONEOS_DEPLOYMENT_TARGET = 15.0`
- **ATT:** Added `NSUserTrackingUsageDescription` in `ios/Runner/Info.plist` (required when using tracking/IDFA on iOS 14.5+).

---

## Common Issues & Fixes

| Issue | Fix |
|-------|-----|
| **Pod install: Firebase/RemoteConfig version conflict** | `cd ios && pod update Firebase/RemoteConfig` or `pod update` |
| **Pod install: “required a higher minimum deployment target”** | Set `platform :ios, '15.0'` in Podfile and `IPHONEOS_DEPLOYMENT_TARGET = 15.0` in Xcode project. |
| **Pod install still failing** | `cd ios && rm Podfile.lock && pod install` (with Xcode selected: `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`) |
| **Ruby/encoding error during pod** | `export LANG=en_US.UTF-8` before running `pod install` |

---

## Quick Reference

- **ODM trigger:** After login, when `identifyUser` runs; iOS only (no-op on Android/Web).
- **Min iOS:** 15.0 (dropped support for iOS 13–14).
- **No extra code** needed for “iOS 15 compatibility” beyond the deployment target and ATT usage description.
