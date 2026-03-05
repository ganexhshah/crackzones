@echo off
REM Flutter Setup and Run Script for Windows
REM This script helps with common Flutter development tasks

echo ========================================
echo    CashCrack Flutter Setup Script
echo ========================================
echo.

:menu
echo.
echo Select an option:
echo.
echo 1. Check Flutter Installation (flutter doctor)
echo 2. Install Dependencies (flutter pub get)
echo 3. Clean and Reinstall Dependencies
echo 4. Run on Connected Device
echo 5. Build Debug APK
echo 6. Build Release APK
echo 7. Generate App Icons
echo 8. Analyze Code
echo 9. Format Code
echo 10. View Connected Devices
echo 11. Install APK on BlueStacks
echo 0. Exit
echo.

set /p choice="Enter your choice (0-11): "

if "%choice%"=="1" goto doctor
if "%choice%"=="2" goto install
if "%choice%"=="3" goto clean
if "%choice%"=="4" goto run
if "%choice%"=="5" goto build_debug
if "%choice%"=="6" goto build_release
if "%choice%"=="7" goto icons
if "%choice%"=="8" goto analyze
if "%choice%"=="9" goto format
if "%choice%"=="10" goto devices
if "%choice%"=="11" goto bluestacks
if "%choice%"=="0" goto end

echo Invalid choice. Please try again.
goto menu

:doctor
echo.
echo Checking Flutter installation...
flutter doctor -v
pause
goto menu

:install
echo.
echo Installing dependencies...
flutter pub get
echo.
echo Dependencies installed successfully!
pause
goto menu

:clean
echo.
echo Cleaning project...
flutter clean
echo.
echo Reinstalling dependencies...
flutter pub get
echo.
echo Clean and reinstall complete!
pause
goto menu

:run
echo.
echo Checking for connected devices...
flutter devices
echo.
echo Starting app on connected device...
flutter run
pause
goto menu

:build_debug
echo.
echo Building debug APK...
flutter build apk --debug
echo.
echo Debug APK built successfully!
echo Location: build\app\outputs\flutter-apk\app-debug.apk
pause
goto menu

:build_release
echo.
echo Building release APK...
flutter build apk --release
echo.
echo Release APK built successfully!
echo Location: build\app\outputs\flutter-apk\app-release.apk
pause
goto menu

:icons
echo.
echo Generating app icons...
flutter pub run flutter_launcher_icons
echo.
echo App icons generated successfully!
pause
goto menu

:analyze
echo.
echo Analyzing code...
flutter analyze
pause
goto menu

:format
echo.
echo Formatting code...
flutter format lib/
echo.
echo Code formatted successfully!
pause
goto menu

:devices
echo.
echo Connected devices:
flutter devices -v
pause
goto menu

:bluestacks
echo.
echo Building debug APK for BlueStacks...
flutter build apk --debug
echo.
echo APK built successfully!
echo.
echo To install on BlueStacks:
echo 1. Open BlueStacks
echo 2. Drag and drop this file into BlueStacks window:
echo    build\app\outputs\flutter-apk\app-debug.apk
echo.
echo Or use ADB:
echo    adb connect localhost:5555
echo    adb install build\app\outputs\flutter-apk\app-debug.apk
echo.
pause
goto menu

:end
echo.
echo Goodbye!
exit
