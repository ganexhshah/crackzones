# Run Flutter App on BlueStacks

## Prerequisites
- BlueStacks installed on your PC
- APK file built (already available in `build/app/outputs/flutter-apk/`)

## Method 1: Install APK via Drag & Drop (Easiest)

1. **Open BlueStacks**
   - Launch BlueStacks on your PC
   - Wait for it to fully load

2. **Install APK**
   - Locate the APK file: `my_app/build/app/outputs/flutter-apk/app-debug.apk`
   - Simply drag and drop the APK file into the BlueStacks window
   - Wait for installation to complete (30-60 seconds)

3. **Launch App**
   - Find the app icon on BlueStacks home screen
   - Click to launch
   - The app should start running!

## Method 2: Install via ADB (Advanced)

1. **Enable ADB in BlueStacks**
   - Open BlueStacks Settings
   - Go to "Advanced" section
   - Enable "Android Debug Bridge (ADB)"
   - Note the ADB port (usually 5555)

2. **Connect via ADB**
   ```bash
   adb connect localhost:5555
   ```

3. **Install APK**
   ```bash
   cd my_app
   adb install build/app/outputs/flutter-apk/app-debug.apk
   ```

4. **Launch App**
   - Find the app in BlueStacks
   - Or launch via ADB:
   ```bash
   adb shell monkey -p com.example.my_app -c android.intent.category.LAUNCHER 1
   ```

## Method 3: Install via APK Installer App

1. **Download APK Installer**
   - Open Google Play Store in BlueStacks
   - Search for "APK Installer"
   - Install any APK installer app

2. **Copy APK to BlueStacks**
   - Use BlueStacks Media Manager
   - Or use shared folder feature
   - Copy `app-debug.apk` to BlueStacks

3. **Install via APK Installer**
   - Open APK Installer app
   - Browse to the APK file
   - Click Install

## Troubleshooting

### App Won't Install
- Make sure BlueStacks is updated to latest version
- Try using `app-debug.apk` instead of `app-release.apk`
- Uninstall any previous version first

### App Crashes on Launch
- Check if backend API is running and accessible
- Verify network settings in BlueStacks
- Check app logs in Android Studio

### Network Issues
- BlueStacks uses your PC's network
- Make sure backend URL is accessible from your PC
- If using localhost, use `10.0.2.2` instead of `localhost` in the app

### Performance Issues
- Allocate more RAM to BlueStacks (Settings > Performance)
- Enable Virtualization in BIOS
- Close other heavy applications

## Building Fresh APK

If you need to rebuild the APK:

### Debug APK (Faster, for testing)
```bash
cd my_app
flutter build apk --debug
```

### Release APK (Optimized, for production)
```bash
cd my_app
flutter build apk --release
```

### Split APKs (Smaller size)
```bash
cd my_app
flutter build apk --split-per-abi
```

## Running Directly from Flutter (Alternative)

Instead of installing APK, you can run directly:

1. **Start BlueStacks**

2. **Connect Flutter to BlueStacks**
   ```bash
   cd my_app
   flutter devices
   ```
   You should see BlueStacks listed

3. **Run App**
   ```bash
   flutter run
   ```
   Select BlueStacks when prompted

4. **Hot Reload**
   - Press `r` for hot reload
   - Press `R` for hot restart
   - Press `q` to quit

## APK Locations

- **Debug APK**: `my_app/build/app/outputs/flutter-apk/app-debug.apk`
- **Release APK**: `my_app/build/app/outputs/flutter-apk/app-release.apk`

## BlueStacks Settings for Best Performance

1. **Performance Settings**
   - CPU: 4 cores
   - RAM: 4GB
   - Performance Mode: High Performance

2. **Display Settings**
   - Resolution: 1920x1080 (or your preference)
   - DPI: 240

3. **Advanced Settings**
   - Enable ADB
   - Enable Root Access (if needed for debugging)

## Useful ADB Commands

```bash
# List connected devices
adb devices

# Install APK
adb install path/to/app.apk

# Uninstall app
adb uninstall com.example.my_app

# View logs
adb logcat

# Take screenshot
adb shell screencap -p /sdcard/screenshot.png
adb pull /sdcard/screenshot.png

# Clear app data
adb shell pm clear com.example.my_app
```

## Notes

- BlueStacks emulates Android 7 (Nougat) or Android 11 depending on version
- Some features may work differently than on real devices
- Camera and some sensors may not work properly
- Use debug APK for testing, release APK for final testing

## Support

- BlueStacks Support: https://support.bluestacks.com
- Flutter Docs: https://docs.flutter.dev
- If app doesn't work, check backend connectivity first
