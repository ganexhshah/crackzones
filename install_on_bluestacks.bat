@echo off
echo ========================================
echo Installing App on BlueStacks
echo ========================================
echo.

REM Set paths
set APK_PATH=%~dp0build\app\outputs\flutter-apk\app-debug.apk
set ANDROID_SDK=%LOCALAPPDATA%\Android\sdk
set ADB=%ANDROID_SDK%\platform-tools\adb.exe

echo Checking for APK file...
if not exist "%APK_PATH%" (
    echo ERROR: APK file not found!
    echo Please build the APK first using: flutter build apk --debug
    pause
    exit /b 1
)
echo APK found: %APK_PATH%
echo.

echo Checking for ADB...
if not exist "%ADB%" (
    echo ERROR: ADB not found at %ADB%
    echo.
    echo Please install Android SDK Platform Tools
    echo Or use the drag-and-drop method instead:
    echo 1. Open BlueStacks
    echo 2. Drag and drop the APK file: %APK_PATH%
    echo 3. Wait for installation to complete
    pause
    exit /b 1
)
echo ADB found: %ADB%
echo.

echo Connecting to BlueStacks...
"%ADB%" connect localhost:5555
timeout /t 2 /nobreak >nul

echo.
echo Installing APK...
"%ADB%" install -r "%APK_PATH%"

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo SUCCESS! App installed on BlueStacks
    echo ========================================
    echo.
    echo You can now find and launch the app from BlueStacks home screen
) else (
    echo.
    echo ========================================
    echo Installation failed!
    echo ========================================
    echo.
    echo Try the manual method:
    echo 1. Open BlueStacks
    echo 2. Drag and drop this file into BlueStacks:
    echo    %APK_PATH%
)

echo.
pause
