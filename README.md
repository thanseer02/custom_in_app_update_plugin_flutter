# custom_app_update

A Flutter **Android plugin** for Google Play flexible in-app updates with UI you
control. Show an update in a bottom sheet, dialog, full screen, banner, or any
other Flutter widget.

The plugin includes its own Kotlin implementation and uses Google's official
`com.google.android.play:app-update:2.1.0` library directly.

> Your Flutter UI surrounds the download and restart experience. Google Play's
> required update confirmation is still shown and cannot be restyled or bypassed.

## Features

- UI-independent `ChangeNotifier` controller.
- Real downloaded/total byte counts and progress from 0 to 1.
- Flexible background downloads that survive closing your custom UI.
- Explicit restart/install action; no automatic install or repeated prompts.
- Downloaded-update recovery when the app returns to the foreground.
- Cancellation, errors, eligibility checks, and duplicate-action guards.
- Runnable example with bottom sheet, dialog, and full-screen presentations.
- Example-only demo backend for local UI testing without Google Play.

## Platform and requirements

| Requirement | Details |
| --- | --- |
| Platform | Android; iOS, web, and desktop updates are not implemented |
| Dart / Flutter | Dart 3.6+, Flutter 3.27+; see validation notes for the SDK actually tested |
| Android minimum | Plugin minSdk 21; keep a higher minimum if your Flutter host requires it |
| Android build tools | compileSdk 36, Java 17, Kotlin 2.2.20, Android Gradle Plugin 8.11.1 |
| Example build tools | Flutter 3.41.2; use its generated Android toolchain or newer compatible tools |
| Real updates | Google Play distribution and an eligible newer versionCode |

The plugin is a development prerelease. See [testing](TESTING.md) and
[publishing](PUBLISHING.md) before releasing it.

Current local validation: 18 tests passed, Flutter analysis passed, and the
Android example compiled. A clean release copy passed the pub publish dry run.
Actual Google Play device testing is still required; see [VALIDATION.md](VALIDATION.md).

## Install locally before publication

Copy or clone this plugin into your repository, then add a **path dependency**
to your app's `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  custom_app_update:
    path: ../custom_app_update
```

Adjust the path to the plugin folder, then run `flutter pub get` and fully rebuild
the app. Hot reload cannot install new native plugin code. Keep the entire plugin
folder: copying only its Dart file omits the Android implementation.

Once you have published the package, consumers can use its hosted dependency:

```yaml
dependencies:
  custom_app_update: ^0.2.0-dev.1
```

## Quick start

Create **one controller above your routes and update surfaces**. A dialog closing
must not dispose the controller that owns its download.

```dart
import 'dart:async';
import 'package:custom_app_update/custom_app_update.dart';
import 'package:flutter/material.dart';

class UpdateHost extends StatefulWidget {
  const UpdateHost({super.key});

  @override
  State<UpdateHost> createState() => _UpdateHostState();
}

class _UpdateHostState extends State<UpdateHost> {
  late final CustomAppUpdateController updates;

  @override
  void initState() {
    super.initState();
    updates = CustomAppUpdateController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(updates.check());
    });
  }

  @override
  void dispose() {
    updates.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('App updates')),
      body: ListenableBuilder(
        listenable: updates,
        builder: (context, _) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (updates.isChecking)
                const CircularProgressIndicator(),
              if (updates.canDownload)
                FilledButton(
                  onPressed: () => unawaited(updates.download()),
                  child: const Text('Download update'),
                ),
              if (updates.phase == UpdatePhase.downloading)
                LinearProgressIndicator(value: updates.downloadProgress),
              if (updates.canInstall)
                FilledButton(
                  onPressed: () => unawaited(updates.restartAndInstall()),
                  child: const Text('Restart and install'),
                ),
              if (updates.error != null)
                const Text('The update could not finish. Please try again.'),
              TextButton(
                onPressed: updates.isChecking
                    ? null
                    : () => unawaited(updates.check()),
                child: const Text('Check for updates'),
              ),
            ],
          );
        },
      ),
    );
  }
}
```

For complete status messages and all three presentation styles, see
[`example/lib/main.dart`](example/lib/main.dart). Its `UpdateContent` widget is
ordinary Flutter UI. Replace it with your design and keep the same controller.

Supply release notes, version labels, and translations from your app; Google
Play's update API does not return your release-note text.

## Controller API

| Member | Meaning |
| --- | --- |
| `check()` | Refresh availability; never opens a prompt |
| `download()` | Request Play consent and download the flexible update |
| `restartAndInstall()` | Install the downloaded update and let Play restart the app |
| `phase` | Current `UpdatePhase` for rendering your own UI |
| `isChecking` | Whether an availability request is running |
| `canDownload` / `canInstall` | Whether the corresponding action can run |
| `downloadProgress` | Actual progress in `[0, 1]`; null before Play knows the size |
| `bytesDownloaded` / `totalBytesToDownload` | Native download byte counts |
| `info` | Latest `AppUpdateInfo`: eligibility, version code, priority, and staleness |
| `error` | Latest error for logging and your own friendly message |

`download()` may remain pending throughout the download. Listen to the controller
rather than waiting for the future to update your screen. On success the phase
becomes `readyToInstall`. Rejecting consent produces `canceled`.

Methods on the controller capture operational failures in `error`. Direct users
of `GooglePlayUpdateBackend` must handle `PlatformException` themselves.

## State flow

```text
check → available → download → Play consent → pending → downloading
                                                        ↓
                                                  readyToInstall
                                                        ↓
                                                restartAndInstall
                                                        ↓
                                              installing → app restart
```

Other phases include `upToDate`, `unavailable`, `unsupported`, `canceled`, and
`failed`. `installed` may be observed, but an actual app restart can occur before
Flutter receives a final callback.

Closing your custom UI does not cancel the download. There is intentionally no
cancel-download API; label dismissal as “Close” or “Continue using app.”
Save unsaved user work before requesting restart. Keep a single controller per
Flutter engine and avoid concurrent independent calls to the native backend.

## Run the example

From the plugin root:

```sh
cd example
flutter pub get
flutter run --dart-define=UPDATE_DEMO=true
```

This runs on a connected Android device or emulator and shows a **DEMO MODE**
label. Try the three UI styles and the Success, Cancel, Download fails, and
Install fails scenarios. The demo performs no actual download, Play consent, or
app restart. Use **Reset demo** to try another run.

For real Google Play testing, omit `UPDATE_DEMO`, build the example, and distribute
it through Play. A locally installed debug APK does not establish Play update
eligibility. Follow the two-version workflow in [TESTING.md](TESTING.md).

## Package layout

```text
lib/                     Public controller, native channel backend, data models
android/                 Kotlin plugin and Google Play library dependency
example/lib/             Custom UI examples and simulated backend
example/android/         Runnable Android host application
test/                    Controller and platform-channel tests
example/test/            Example widget tests
TESTING.md               Local and real-device testing instructions
PUBLISHING.md            Maintainer release instructions
```

## Troubleshooting

| Symptom | Check |
| --- | --- |
| `MissingPluginException` | Add the entire path/hosted plugin dependency and do a full rebuild |
| `UPDATE_UNAVAILABLE` / no update | Play account access, distribution, rollout, versionCode, and flexible eligibility |
| No numeric progress yet | Play has not reported a positive total size; show indeterminate progress |
| `NO_ACTIVITY` | Start the download or install while your app is in the foreground |
| `NOT_DOWNLOADED` | Wait for `canInstall` before requesting installation |
| `CHECK_FAILED`, `DOWNLOAD_FAILED`, `INSTALL_FAILED` | Log `error`; native `PlatformException.details` can contain a Play error code |
| Gradle or Kotlin incompatibility | Match the Android build toolchain listed above; compare the example host |

## References

- [Google Play in-app updates](https://developer.android.com/guide/playcore/in-app-updates)
- [Android implementation guide](https://developer.android.com/guide/playcore/in-app-updates/kotlin-java)
- [Google Play testing guide](https://developer.android.com/guide/playcore/in-app-updates/test)
- [Flutter plugin development](https://docs.flutter.dev/packages-and-plugins/developing-packages)

## License

BSD-3-Clause. See [LICENSE](LICENSE).
