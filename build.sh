#!/bin/bash

# run flutter apk build command
flutter build apk --release
# List connected devices
devices=$(adb devices | grep -v "List of devices" | awk '{print $1}')

# Path to the APK file
apk_file="build/app/outputs/flutter-apk/app-release.apk"

# Install the APK on all connected devices
for device in $devices; do
    adb -s $device install $apk_file
done

flutter build apk --release --split-per-abi
flutter build ipa --export-method development
