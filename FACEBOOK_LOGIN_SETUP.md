# Facebook Login Setup Guide

## Overview
This guide will help you configure Facebook Login for your Lavender AI App on Android.

## Your Facebook App Credentials

| Property | Value |
|----------|-------|
| **App ID** | `1431868658731551` |
| **Display Name** | SmartGreenHouse |
| **App Secret** | `69e0ab8371198493cbf02c13ba2dffda` |
| **Package Name** | `com.example.lavender_ai_app` |

## Prerequisites
- Facebook Developer Account
- Your app's package name: `com.example.lavender_ai_app`
- Your app is already running on a device

## Step 1: Create a Facebook App

1. Go to [Facebook for Developers](https://developers.facebook.com/)
2. Click **"My Apps"** in the top right
3. Click **"Create App"**
4. Select **"Consumer"** as the app type
5. Click **"Next"**
6. Enter:
   - **App Name**: SmartGreenHouse (Display Name)
   - **App ID**: 1431868658731551
   - **App Contact Email**: your-email@example.com
8. Click **"Create App"**

**Note**: Your app is already created with these credentials.

## Step 2: Configure Facebook Login

1. In your Facebook App Dashboard, click **"Set Up"** on **Facebook Login**
2. Select **"Android"** as your platform
3. Skip the download SDK step (we're using Flutter package)

## Step 3: Configure Android Settings

### Get Your Key Hash

Run this command in PowerShell to get your debug key hash:

```powershell
keytool -exportcert -alias androiddebugkey -keystore "$env:USERPROFILE\.android\debug.keystore" | openssl sha1 -binary | openssl base64
```

**Default password when prompted**: `android`

Copy the output hash (it will look like: `a1b2C3D4e5F6...`)

### Add Android Platform

1. In Facebook App Dashboard, go to **Settings → Basic**
2. Click **"Add Platform"** at the bottom
3. Select **"Android"**
4. Fill in:
   - **Package Name**: `com.example.lavender_ai_app`
   - **Class Name**: `com.example.lavender_ai_app.MainActivity`
   - **Key Hashes**: Paste your key hash from above
5. Click **"Save Changes"**

## Step 4: Get App ID and Client Token

1. In your Facebook App Dashboard, go to **Settings → Basic**
2. Copy your **App ID**: `1431868658731551`
3. Copy your **App Secret**: `69e0ab8371198493cbf02c13ba2dffda`

## Step 5: Configure Android App

### Update AndroidManifest.xml

Open `android/app/src/main/AndroidManifest.xml` and add inside the `<application>` tag:

```xml
<!-- Facebook Configuration -->
<meta-data
    android:name="com.facebook.sdk.ApplicationId"
    android:value="@string/facebook_app_id"/>

<meta-data
    android:name="com.facebook.sdk.ClientToken"
    android:value="@string/facebook_client_token"/>

<activity
    android:name="com.facebook.FacebookActivity"
    android:configChanges="keyboard|keyboardHidden|screenLayout|screenSize|orientation"
    android:label="@string/app_name" />

<activity
    android:name="com.facebook.CustomTabActivity"
    android:exported="true">
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="@string/fb_login_protocol_scheme" />
    </intent-filter>
</activity>
```

### Create strings.xml

Create or update `android/app/src/main/res/values/strings.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">Lavender AI App</string>
    <string name="facebook_app_id">YOUR_APP_ID_HERE</string>
    <string name="facebook_client_token">YOUR_CLIENT_TOKEN_HERE</string>
    <string name="fb_login_protocol_scheme">fbYOUR_APP_ID_HERE</string>
</resources>
```

Replace:
- `YOUR_APP_ID_HERE` with `1431868658731551`
- `YOUR_CLIENT_TOKEN_HERE` with `69e0ab8371198493cbf02c13ba2dffda`

**Your Configuration**:
```xml
<string name="facebook_app_id">1431868658731551</string>
<string name="facebook_client_token">69e0ab8371198493cbf02c13ba2dffda</string>
<string name="fb_login_protocol_scheme">fb1431868658731551</string>
```

## Step 6: Update build.gradle (Optional)

Open `android/app/build.gradle.kts` and ensure minSdk is at least 21:

```kotlin
defaultConfig {
    minSdk = 23  // Already set correctly
}
```

## Step 7: Enable Firebase Facebook Authentication

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **research-auth-app-88361**
3. Go to **Authentication → Sign-in method**
4. Click on **Facebook**
5. Click **Enable**
6. Enter your:
   - **App ID**: From Facebook Developer Console
   - **App Secret**: From Facebook Developer Console
7. Copy the **OAuth redirect URI** shown
8. Go back to Facebook Developer Console
9. Go to **Facebook Login → Settings**
10. Add the OAuth redirect URI to **Valid OAuth Redirect URIs**
11. Click **Save Changes**

## Step 8: Test Facebook Login

1. Run the app on your device:
   ```bash
   flutter run -d R58RC1HD67P
   ```

2. On the login screen, tap the **Facebook icon** button
3. Log in with your Facebook credentials
4. Grant permissions to the app
5. You should be logged in successfully!

## Troubleshooting

### "Invalid key hash"
- Make sure you generated the key hash correctly
- For release builds, use your release keystore
- Add multiple key hashes if testing on multiple machines

### "App not set up"
- Ensure your Facebook App is in **Development Mode** (Settings → Basic)
- Add your Facebook account as a test user (Roles → Test Users)

### "Callback URL mismatch"
- Ensure the OAuth redirect URI in Firebase matches what you added in Facebook Developer Console
- Format should be: `https://research-auth-app-88361.firebaseapp.com/__/auth/handler`

### Login button doesn't work
- Check that `strings.xml` has the correct App ID
- Verify `AndroidManifest.xml` has all required entries
- Run `flutter clean` and rebuild

## Features Implemented

✅ **Facebook Authentication** - Users can sign in with their Facebook account  
✅ **Dynamic Date/Time Display** - Header shows current date and time
✅ **Dynamic Activity Times** - Activity feed shows relative timestamps (5 mins ago, 1 hour ago, etc.)
✅ **Google Sign-In** - Already implemented
✅ **Biometric Login** - Fingerprint/Face ID authentication
✅ **Profile Management** - Upload profile pictures, edit name, change password

## Files Modified

- `lib/screens/login_screen.dart` - Added Facebook login handler
- `lib/screens/dashboard_screen.dart` - Dynamic date/time and activity times
- `lib/screens/climate_screen.dart` - Dynamic activity times
- `pubspec.yaml` - Added flutter_facebook_auth and intl packages

## Next Steps

1. Test Facebook login on your device
2. Add more test users in Facebook Developer Console
3. When ready for production, switch app to **Live Mode**
4. Submit app for Facebook App Review if needed

## Support

For issues with:
- **Flutter Facebook Auth**: https://pub.dev/packages/flutter_facebook_auth
- **Facebook Login**: https://developers.facebook.com/docs/facebook-login
- **Firebase Auth**: https://firebase.google.com/docs/auth
