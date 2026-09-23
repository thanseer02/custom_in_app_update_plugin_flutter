# custom_in_app_update

A Flutter plugin for in-app updates that lets **your app own the UI**.

- **Android**: wraps Google Play's [In-App Update API](https://developer.android.com/guide/playcore/in-app-updates) (immediate + flexible flows, download progress, stalled-update resume).
- **iOS**: no native in-app-update API exists, so this checks the installed version against the App Store via the public iTunes Lookup API.
- **Custom UI**: instead of forcing a fixed dialog, you pass a `uiBuilder` that receives the update data plus `onUpdate` / `onDismiss` callbacks — render a bottom sheet, a banner, a full-screen page, anything.

## Install

This package isn't published to pub.dev, so add it as a **local path** or
**git** dependency in your app's `pubspec.yaml`.

### Option A — local path (plugin lives inside your project, e.g. `packages/custom_in_app_update`)

```yaml
dependencies:
  flutter:
    sdk: flutter
  custom_in_app_update:
    path: packages/custom_in_app_update
```

### Option B — git dependency (plugin lives in its own repo)

```yaml
dependencies:
  flutter:
    sdk: flutter
  custom_in_app_update:
    git:
      url: https://github.com/your-org/custom_in_app_update.git
      ref: main   # or a tag/commit for a pinned version
```

Then fetch it:

```bash
flutter pub get
```

### Android setup

No manual native setup needed — the plugin bundles the Play Core
`app-update` dependency itself. Just confirm your app's
`android/app/build.gradle` has `minSdkVersion 21` or higher.

### iOS setup

No native setup needed either — the iOS path is pure Dart (App Store
lookup). You just need to pass `iosBundleId` and `iosInstalledVersion`
when calling `checkForUpdate` (see below). `iosInstalledVersion` is
easiest to get from the `package_info_plus` package:

```yaml
dependencies:
  package_info_plus: ^8.0.0
```

```dart
final info = await PackageInfo.fromPlatform();
final installedVersion = info.version;
```

## Basic usage (built-in default dialog)

```dart
await CustomInAppUpdate.checkForUpdate(
  context: context,
  iosBundleId: 'com.company.app',
  iosInstalledVersion: packageInfo.version, // from package_info_plus
);
```

## Custom UI — bottom sheet

```dart
await CustomInAppUpdate.checkForUpdate(
  context: context,
  iosBundleId: 'com.company.app',
  iosInstalledVersion: packageInfo.version,
  uiBuilder: (context, info, onUpdate, onDismiss) {
    showModalBottomSheet(
      context: context,
      isDismissible: !info.immediateAllowed,
      builder: (_) => MyUpdateSheet(
        info: info,
        onUpdate: onUpdate,
        onDismiss: onDismiss,
      ),
    );
    return null;
  },
);
```

## Custom UI — anything else (banner, full page, snackbar...)

`uiBuilder` can return `null` and manage its own state/widget tree instead
of relying on `Navigator` — see the banner example in `example/lib/main.dart`.

## Tracking flexible-update download progress

```dart
StreamBuilder<UpdateInfo>(
  stream: CustomInAppUpdate.downloadProgressStream,
  builder: (context, snapshot) {
    final progress = snapshot.data?.downloadProgress;
    return progress == null
        ? const SizedBox.shrink()
        : LinearProgressIndicator(value: progress / 100);
  },
)
```

## Resuming interrupted immediate updates

Call this from `didChangeAppLifecycleState` on resume:

```dart
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.resumed) {
    CustomInAppUpdate.resumeStalledUpdateIfNeeded();
  }
}
```

## Notes

- Android in-app updates only work with builds installed **from the Play Store** (internal testing tracks included) — not `flutter run` / `adb install` / sideloaded APKs.
- Play Store rollout/caching can delay when a newly-published version is detected.
- iOS: since there's no native update flow, your `onUpdate` callback should deep-link to the App Store URL rather than expecting a system flow to start.

## Testing

### Local Test Mode (No Play Store Required)
You can test your custom UI locally using Google's `FakeAppUpdateManager`. 
**Important:** You should wrap this in a `kDebugMode` check so you don't accidentally release your app in test mode!

```dart
import 'package:flutter/foundation.dart';

// 1. Conditionally enable test mode for debug builds only
if (kDebugMode) {
  await CustomInAppUpdate.enableTestMode();
  await CustomInAppUpdate.setTestUpdateAvailable(
    flexibleAllowed: true,
    immediateAllowed: true,
  );
}

// 2. Trigger your update check as normal
await CustomInAppUpdate.checkForUpdate(...);
```
*(If you are testing flexible updates locally, you can also use `CustomInAppUpdate.simulateDownloadProgress(bytesDownloaded: 50, totalBytesToDownload: 100)` to simulate download progress in the UI).*

### Real Play Store Testing
1. Publish version A to a Play Store internal testing track, install it via the Play Store link (not adb).
2. Publish version B (higher version code) to the same track.
3. Open the app and call `checkForUpdate` — allow a few minutes for Play Store propagation.
