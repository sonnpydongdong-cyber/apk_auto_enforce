#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$ROOT_DIR/TuokeApk"
APK_PATH="$PROJECT_DIR/app/build/outputs/apk/app-debug.apk"

if ! command -v adb >/dev/null 2>&1; then
    echo "Error: adb is not installed or is not on PATH." >&2
    exit 1
fi

"$PROJECT_DIR/gradlew" --project-dir "$PROJECT_DIR" :app:assembleDebug

if [[ ! -f "$APK_PATH" ]]; then
    echo "Error: expected debug APK was not created: $APK_PATH" >&2
    exit 1
fi

adb start-server

if [[ -n "${ANDROID_SERIAL:-}" ]]; then
    DEVICE="$ANDROID_SERIAL"
    DEVICE_STATE="$(adb -s "$DEVICE" get-state 2>/dev/null || true)"
    if [[ "$DEVICE_STATE" != "device" ]]; then
        echo "Error: ANDROID_SERIAL '$DEVICE' is not an authorized connected device." >&2
        adb devices
        exit 1
    fi
else
    mapfile -t DEVICES < <(adb devices | awk 'NR > 1 && $2 == "device" { print $1 }')
    if [[ "${#DEVICES[@]}" -ne 1 ]]; then
        echo "Error: expected exactly one authorized Android device; found ${#DEVICES[@]}." >&2
        echo "Connect and authorize one device, or set ANDROID_SERIAL to select one." >&2
        adb devices
        exit 1
    fi
    DEVICE="${DEVICES[0]}"
fi

adb -s "$DEVICE" install -r "$APK_PATH"
echo "Installed the project Debug APK on $DEVICE."
