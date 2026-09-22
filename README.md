# Custom Flutter in-app updates

A UI-independent controller for Google Play flexible updates. Design your own
bottom sheet, dialog, page, banner, or widget. Google Play still presents its
required consent UI. Downloads and installation use Google Play.

## Add to your app

Copy `lib/custom_app_update.dart` into your app, then run:

```sh
flutter pub add in_app_update:^4.2.5
```

Alternatively, copy this folder into your repository and add a path dependency:

```yaml
dependencies:
  custom_app_update:
    path: packages/custom_app_update
```

With a path dependency, import:

```dart
import 'package:custom_app_update/custom_app_update.dart';
```

If you copied the Dart file, use your local import instead.

## Any UI works

Create one `CustomAppUpdateController` in an app-level State, provider, or other
owner that outlives your update UI. Call `check()` once after the first frame.
Dispose the controller when its owner is destroyed, not when a sheet closes.
The controller refreshes its state when the app resumes; checks never open UI.

```dart
ListenableBuilder(
  listenable: updates,
  builder: (context, _) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(updates.phase.name), // Replace with your user-facing copy.
      if (updates.phase == UpdatePhase.downloading)
        const LinearProgressIndicator(),
      if (updates.canDownload)
        FilledButton(
          onPressed: updates.download,
          child: const Text('Update'),
        ),
      if (updates.canInstall)
        FilledButton(
          onPressed: updates.restartAndInstall,
          child: const Text('Restart'),
        ),
    ],
  ),
)
```

Place that builder in `showModalBottomSheet`, `showDialog`, or a `Scaffold`.
`example/main.dart` contains all three presentations and controller ownership.
To run it, use it as `lib/main.dart` in an Android-enabled Flutter application
with this package as a dependency. This folder is a Dart/Flutter package, not
an Android application with a generated host project.

## API

| Member | Use |
| --- | --- |
| `check()` | Refresh availability without prompting |
| `download()` | Show Play consent, then download in the background |
| `restartAndInstall()` | Install after the user chooses Restart |
| `phase` | Render available, downloading, ready, canceled, etc. |
| `isChecking` | Render the availability check indicator |
| `canDownload`, `canInstall` | Enable the corresponding buttons |
| `info` | Inspect version code, priority, and eligibility |
| `error` | Log technical failures; show your own friendly message |
| `downloadProgress` | Always null: use indeterminate progress |

## Behavior and limits

- `in_app_update` exposes installation states, not byte counts. A real
  percentage requires extending the native plugin to expose downloaded/total
  bytes. This implementation does not fabricate progress.
- Your app supplies release notes, version labels, colors, and copy. The API
  does not supply your release-note text.
- Closing a sheet or dialog does not cancel the Play download. There is no
  public cancel-download method in this package; label dismissal accordingly.
- A rejected Play prompt produces `canceled`, not an exception to show users.
- A downloaded update recovered on resume becomes `readyToInstall`.
- Checks and repeated Download/Restart taps are guarded against duplicates.
- Call `download()` only in response to your user choosing Update. The
  controller never automatically shows prompts on resume.
- Save unsaved work before `restartAndInstall()`. The app may restart before
  its future resolves. Call this action from a foreground screen.
- Use one controller and avoid separate direct calls to `InAppUpdate` elsewhere;
  the underlying plugin keeps shared native update state.
- Android only. Google Play decides eligibility, including rollout and account
  access. A public release does not mean every user immediately sees an update.

## Validation

This package uses `in_app_update` 4.2.5 for compatibility with the installed
Flutter 3.41.2 / Dart 3.11 SDK. Version 5.0.0 requires Dart 3.12 or newer.

Verified here: `flutter analyze` passed with no issues, and all 8 controller
tests passed. A real Google Play download/install was not run in this workspace.

```sh
flutter pub get
flutter analyze
flutter test
```

Tests use an injected backend to exercise the controller. Real consent,
downloads, installation, and app restart require a device and Play distribution.

For an end-to-end test, install a lower version through a Play testing track,
publish a higher versionCode accessible to the same tester, then exercise the
custom sheet/dialog/page. Keep the application ID and signing key consistent.
Also test rejection, dismissing the custom UI during download, returning to the
app after download, and Restart. Internal app sharing has its own workflow in
Google's testing guide; follow those instructions if using it instead.

Sources:
- https://pub.dev/packages/in_app_update
- https://pub.dev/documentation/in_app_update/latest/in_app_update/InAppUpdate-class.html
- https://developer.android.com/guide/playcore/in-app-updates/kotlin-java
- https://developer.android.com/guide/playcore/in-app-updates/test
# custom_in_app_update_plugin_flutter
