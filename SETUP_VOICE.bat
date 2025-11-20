@echo off
echo ========================================
echo Voice Chat Setup Script
echo ========================================
echo.
echo This script will:
echo 1. Clean the Flutter build cache
echo 2. Remove pubspec.lock
echo 3. Install all dependencies
echo 4. Build the app with voice support
echo.
pause

echo.
echo Step 1: Cleaning Flutter build cache...
call flutter clean

echo.
echo Step 2: Removing pubspec.lock...
if exist pubspec.lock del pubspec.lock

echo.
echo Step 3: Getting Flutter dependencies...
call flutter pub get

echo.
echo Step 4: Building the app...
echo Please connect your device and press any key to continue...
pause

call flutter run

echo.
echo ========================================
echo Setup Complete!
echo ========================================
echo.
echo IMPORTANT: When you first tap the microphone icon,
echo Android will ask for microphone permission.
echo Make sure to ALLOW it!
echo.
pause
