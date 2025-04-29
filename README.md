# flutter_assets_monitoring

A new Flutter project.

## Firebase Cloud Messaging Setup

Follow these steps to set up Firebase Cloud Messaging (FCM) in your app:

### 1. Create a Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/) and create a new project
2. Add your Android and iOS apps to the project following the Firebase setup wizard

### 2. Download and Add Configuration Files

#### For Android:
1. Download the `google-services.json` file from Firebase console
2. Place it in the `android/app/` directory

#### For iOS:
1. Download the `GoogleService-Info.plist` file from Firebase console
2. Add it to your iOS project using XCode (right-click on the Runner directory and select "Add Files to Runner")

### 3. Update Firebase Options

Replace the placeholder values in `lib/firebase_options.dart` with the actual values from your Firebase project.

### 4. Test FCM Integration

1. Run the app and check the console logs for the FCM token
2. You can view your FCM token in the app by navigating to the notification settings page
3. Send a test notification from the Firebase console to verify everything works

## Push Notification Features

This app includes:

- Background message handling (notifications appear even when app is closed)
- Foreground message handling with custom notifications
- FCM token management (automatic refresh and server sync)
- Notification settings page for users

## API Integration

The app automatically sends the FCM token to your server during login. Make sure your server API is set up to store and use these tokens for sending targeted notifications.

## Troubleshooting

- If you're not receiving notifications, check that you've granted notification permissions to the app
- Verify that the FCM token is being sent to your server correctly
- Test sending messages directly from the Firebase console to isolate any issues

## Getting Started with Flutter

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
