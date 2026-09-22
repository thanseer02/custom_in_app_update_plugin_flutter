# Architecture

The `flutter_in_app_update` plugin follows a standard Flutter plugin architecture, separating the public Dart API from the platform-specific native implementations.

## Overview
1. **Dart API**: Provides a unified, platform-agnostic interface for Flutter applications to check for updates, initiate update flows, and monitor progress.
2. **Method Channel**: Used for standard asynchronous calls between Dart and native platforms (e.g., checking for updates, starting an update).
3. **Event Channel**: Used for streaming update progress and status changes from Android to Dart.
4. **Android Native (Kotlin)**: Wraps the official Google Play In-App Updates API (`com.google.android.play:app-update-ktx`).
5. **iOS Native (Swift)**: Implements custom logic to query the iTunes Lookup API for version comparison and utilizes `SKStoreProductViewController` or deep links to open the App Store.

## Android Implementation
- Uses `AppUpdateManagerFactory.create(context)`
- Exposes flexible and immediate update flows.
- Uses `InstallStateUpdatedListener` to listen to flexible update download progress and statuses.
- Passes data back to Dart via EventChannel.

## iOS Implementation
- iOS lacks a direct system-level API for in-app updates like Android.
- The plugin will fetch app details from `https://itunes.apple.com/lookup?bundleId={bundle_id}`.
- Compares the remote version against the local `CFBundleShortVersionString`.
- Opens the App Store via `UIApplication.shared.open(url)` or `SKStoreProductViewController`.

## State Management
- Native code maps internal states to standard string/integer codes.
- Dart code parses these into sealed classes/enums (e.g., `UpdateInstallStatus`).
