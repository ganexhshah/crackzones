# Flutter App Setup Guide

Complete guide to set up and run the CashCrack Flutter mobile application.

## Prerequisites

### Required Software
1. **Flutter SDK** (3.11.0 or higher)
   - Download from: https://docs.flutter.dev/get-started/install
   - Add Flutter to your PATH

2. **Android Studio** (for Android development)
   - Download from: https://developer.android.com/studio
   - Install Android SDK and emulator

3. **Xcode** (for iOS development - macOS only)
   - Install from Mac App Store
   - Install Xcode Command Line Tools

4. **Git**
   - Download from: https://git-scm.com/downloads

5. **VS Code** (recommended) or Android Studio
   - VS Code: Install Flutter and Dart extensions

### Verify Installation

```bash
# Check Flutter installation
flutter doctor

# This should show checkmarks for:
# - Flutter SDK
# - Android toolchain
# - Chrome (for web)
# - VS Code or Android Studio
# - Connected devices
```

## Project Setup

### 1. Clone and Navigate

```bash
cd my_app
```

### 2. Install Dependencies

```bash
# Get all Flutter packages
flutter pub get

# If you encounter issues, try:
flutter clean
flutter pub get
```

### 3. Configure Firebase (Required for Push Notifications)

#### Android Configuration
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or use existing one
3. Add Android app with package name: `com.example.my_app`
4. Download `google-services.json`
5. Place it in: `my_app/android/app/google-services.json`

#### iOS Configuration (macOS only)
1. In Firebase Console, add iOS app
2. Download `GoogleService-Info.plist`
3. Place it in: `my_app/ios/Runner/GoogleService-Info.plist`

### 4. Configure API Endpoint

Edit the API base URL in your app to point to your backend:

```dart
// lib/services/api_service.dart
// Update the base URL to your backend URL
static const String baseUrl = 'https://your-backend-url.com';
```

### 5. Generate App Icons (Optional)

```bash
# Generate launcher icons
flutter pub run flutter_launcher_icons
```

## Running the App

### Option 1: Run on Physical Device

#### Android Device
1. Enable Developer Options on your phone:
   - Go to Settings > About Phone
   - Tap "Build Number" 7 times
   
2. Enable USB Debugging:
   - Settings > Developer Options > USB Debugging

3. Connect device via USB

4. Run the app:
```bash
flutter devices  # Verify device is connected
flutter run
```

#### iOS Device (macOS only)
1. Connect iPhone via USB
2. Trust the computer on your iPhone
3. Open Xcode and sign the app with your Apple ID
4. Run:
```bash
flutter run
```

### Option 2: Run on Emulator

#### Android Emulator
```bash
# List available emulators
flutter emulators

# Launch an emulator
flutter emulators --launch <emulator_id>

# Or open Android Studio > AVD Manager > Start emulator

# Run the app
flutter run
```

#### iOS Simulator (macOS only)
```bash
# Open simulator
open -a Simulator

# Run the app
flutter run
```

### Option 3: Run on BlueStacks

See [BLUESTACKS_SETUP.md](./BLUESTACKS_SETUP.md) for detailed instructions.

Quick steps:
```bash
# Build APK
flutter build apk --debug

# Drag and drop the APK to BlueStacks
# APK location: build/app/outputs/flutter-apk/app-debug.apk
```

## Building for Production

### Android APK

```bash
# Build debug APK (for testing)
flutter build apk --debug

# Build release APK (for production)
flutter build apk --release

# Build split APKs (smaller size, recommended)
flutter build apk --split-per-abi --release
```

APK locations:
- Debug: `build/app/outputs/flutter-apk/app-debug.apk`
- Release: `build/app/outputs/flutter-apk/app-release.apk`

### Android App Bundle (for Play Store)

```bash
# Build app bundle
flutter build appbundle --release
```

Bundle location: `build/app/outputs/bundle/release/app-release.aab`

### iOS (macOS only)

```bash
# Build iOS app
flutter build ios --release

# Or build IPA for distribution
flutter build ipa --release
```

## Development Workflow

### Hot Reload
While the app is running:
- Press `r` in terminal for hot reload (fast, preserves state)
- Press `R` for hot restart (slower, resets state)
- Press `q` to quit

### Debugging

```bash
# Run in debug mode with verbose logging
flutter run -v

# Run with specific device
flutter run -d <device_id>

# View logs
flutter logs
```

### Code Analysis

```bash
# Analyze code for issues
flutter analyze

# Format code
flutter format lib/

# Run tests
flutter test
```

## Project Structure

```
my_app/
├── android/          # Android-specific code
├── ios/              # iOS-specific code
├── lib/              # Dart source code
│   ├── main.dart     # App entry point
│   ├── screens/      # UI screens
│   ├── widgets/      # Reusable widgets
│   ├── services/     # API and services
│   └── models/       # Data models
├── assets/           # Images, fonts, etc.
├── test/             # Unit and widget tests
└── pubspec.yaml      # Dependencies and config
```

## Common Issues & Solutions

### Issue: "Flutter SDK not found"
```bash
# Add Flutter to PATH (Windows)
setx PATH "%PATH%;C:\path\to\flutter\bin"

# Add Flutter to PATH (macOS/Linux)
export PATH="$PATH:/path/to/flutter/bin"
```

### Issue: "Android licenses not accepted"
```bash
flutter doctor --android-licenses
# Accept all licenses
```

### Issue: "CocoaPods not installed" (macOS)
```bash
sudo gem install cocoapods
cd ios
pod install
```

### Issue: "Gradle build failed"
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

### Issue: "Unable to connect to backend"
- Verify backend is running
- Check API URL in `lib/services/api_service.dart`
- For localhost on emulator, use:
  - Android: `10.0.2.2` instead of `localhost`
  - iOS: `localhost` works fine

### Issue: "Google Sign-In not working"
- Ensure Firebase is configured correctly
- Add SHA-1 fingerprint to Firebase Console:
```bash
cd android
./gradlew signingReport
```

## Environment-Specific Configuration

### Development
```dart
// Use local backend
static const String baseUrl = 'http://10.0.2.2:3000';
```

### Staging
```dart
// Use staging backend
static const String baseUrl = 'https://staging-api.example.com';
```

### Production
```dart
// Use production backend
static const String baseUrl = 'https://api.example.com';
```

## Performance Optimization

### Build Optimization
```bash
# Build with optimization flags
flutter build apk --release --shrink --obfuscate --split-debug-info=./debug-info
```

### Profile Mode
```bash
# Run in profile mode to measure performance
flutter run --profile
```

### Analyze App Size
```bash
# Analyze APK size
flutter build apk --analyze-size
```

## Testing

### Run All Tests
```bash
flutter test
```

### Run Specific Test
```bash
flutter test test/widget_test.dart
```

### Integration Tests
```bash
flutter drive --target=test_driver/app.dart
```

## Deployment

### Google Play Store
1. Build app bundle: `flutter build appbundle --release`
2. Sign the bundle with your keystore
3. Upload to Google Play Console
4. Fill in store listing details
5. Submit for review

### Apple App Store (macOS only)
1. Build IPA: `flutter build ipa --release`
2. Open Xcode and archive the app
3. Upload to App Store Connect
4. Fill in app information
5. Submit for review

## Useful Commands

```bash
# Update Flutter
flutter upgrade

# Check for outdated packages
flutter pub outdated

# Update packages
flutter pub upgrade

# Clean build files
flutter clean

# Get device info
flutter devices -v

# Take screenshot
flutter screenshot

# Open DevTools
flutter pub global activate devtools
flutter pub global run devtools
```

## Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- [Flutter Packages](https://pub.dev/)
- [Flutter Community](https://flutter.dev/community)
- [Stack Overflow - Flutter](https://stackoverflow.com/questions/tagged/flutter)

## Support

For project-specific issues:
1. Check existing documentation
2. Review backend API documentation
3. Check Firebase configuration
4. Verify network connectivity

## Next Steps

1. Complete Firebase setup
2. Configure API endpoints
3. Test on physical device
4. Build and test release APK
5. Prepare for store submission

---

**Note**: Always test on both Android and iOS devices before releasing to production.
