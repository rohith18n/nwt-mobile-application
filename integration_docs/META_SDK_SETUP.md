# Meta (Facebook) SDK Setup Guide

## Overview
Meta SDK has been integrated for app install tracking and ad campaign optimization.

## What Was Done
✅ Added `facebook_app_events: ^0.19.0` to pubspec.yaml  
✅ Created `MetaAppEventsService` for logging events  
✅ Added `fb_mobile_activate_app` event on app launch in main.dart  

## Remaining Steps (REQUIRED before going live)

### Step 1: Create Meta App & Get App ID
1. Go to https://developers.facebook.com/
2. Create a new app (Select "Build Connected Experiences")
3. Note down your **App ID** and **App Secret**

### Step 2: Android Setup

#### 2.1 Add to `android/app/src/main/res/values/strings.xml`:
```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="facebook_app_id">YOUR_APP_ID</string>
    <string name="fb_login_protocol_scheme">fbYOUR_APP_ID</string>
</resources>
```

#### 2.2 Add to `android/app/src/main/AndroidManifest.xml` inside `<application>` tag:
```xml
<meta-data android:name="com.facebook.sdk.ApplicationId" android:value="@string/facebook_app_id"/>
<meta-data android:name="com.facebook.sdk.ClientToken" android:value="YOUR_CLIENT_TOKEN"/>

<!-- Add this activity for App Events -->
<activity android:name="com.facebook.FacebookActivity" 
          android:configChanges="keyboard|keyboardHidden|screenLayout|screenSize|orientation"
          android:label="@string/app_name" />
```

### Step 3: iOS Setup

#### 3.1 Add to `ios/Runner/Info.plist`:
```xml
<key>FacebookAppID</key>
<string>YOUR_APP_ID</string>
<key>FacebookClientToken</key>
<string>YOUR_CLIENT_TOKEN</string>
<key>FacebookDisplayName</key>
<string>Networth Tracker</string>

<!-- SKAdNetwork for iOS 14.5+ (REQUIRED for Meta Ads) -->
<key>SKAdNetworkItems</key>
<array>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>v9wttpbfk9.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>n38lu8286q.skadnetwork</string>
    </dict>
</array>

<!-- Required for iOS 14+ ATT (App Tracking Transparency) -->
<key>NSUserTrackingUsageDescription</key>
<string>This identifier will be used to deliver personalized ads to you.</string>
```

### Step 4: Meta Events Manager Setup
1. Go to Meta Events Manager: https://business.facebook.com/events_manager
2. Click "Connect Data Sources" → "App"
3. Select your app and follow the setup wizard
4. Enable "Automatic App Event Logging" 

### Step 5: Test the Integration

#### Test on Android:
```bash
# Build and run
flutter run

# Check logcat for Facebook SDK logs
adb logcat | grep -i facebook
```

#### Test on iOS:
```bash
# Build and run
flutter run

# Check Xcode console for Facebook SDK logs
```

### Step 6: Verify in Meta Events Manager
1. Go to https://business.facebook.com/events_manager
2. Select your app
3. Look for `fb_mobile_activate_app` events coming through
4. Wait 15-30 minutes for events to appear

## Important Notes

⚠️ **Before launching ads**:
- Test the integration thoroughly
- Ensure `fb_mobile_activate_app` is firing correctly
- Complete the Events Manager setup
- Wait 1-2 days for Meta to verify the integration

⚠️ **iOS 14.5+ Requirements**:
- SKAdNetwork configuration is **mandatory**
- App Tracking Transparency (ATT) permission is recommended
- Without these, Meta cannot track iOS installs properly

## Additional Events You Can Log

The service supports other standard Meta events:

```dart
// Log registration
MetaAppEventsService().logCompletedRegistration(registrationMethod: 'email');

// Log purchase
MetaAppEventsService().logPurchase(
  amount: 99.99,
  currency: 'INR',
);

// Log custom event
MetaAppEventsService().logEvent(
  name: 'level_achieved',
  parameters: {'level': 5},
);
```

## Support
- Meta Developer Docs: https://developers.facebook.com/docs/app-events
- Flutter Package: https://pub.dev/packages/facebook_app_events
