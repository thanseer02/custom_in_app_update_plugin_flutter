# Testing custom_app_update

## 1. Automated checks

From the plugin root:

```sh
flutter pub get
flutter analyze
flutter test
cd example
flutter test
flutter build apk --debug --dart-define=UPDATE_DEMO=true
```

Controller and channel tests use fake responses. Example widget tests exercise
opening a sheet, starting a download, closing it, observing the same state in a
dialog, and finishing through a full screen. These do not prove actual Play
eligibility, consent, network download, installation, or restart.

## 2. Local interactive demo

```sh
cd example
flutter run --dart-define=UPDATE_DEMO=true
```

Select a scenario, open any presentation, and tap Download update.

| Scenario | Expected |
| --- | --- |
| Success | Progress reaches completion; Finish demo installation changes state to installed |
| Cancel | Canceled message; Download update can be pressed again |
| Download fails | Failure around 40%; retry remains possible |
| Install fails | Download succeeds; finish reports an error and keeps the install action available |

Close a sheet during download, then open the dialog or full-screen version.
Progress should continue. Change scenarios or use Reset demo after the active
operation finishes. The simulation does not show Google Play's consent dialog.

## 3. Real update using internal app sharing

Use an Android phone with Google Play and a Play Console app you own. Configure
the example application's ID for that app, or add this plugin to your existing
Play-distributed Flutter app. Its ID and signing identity must remain consistent.

The example's generated release build uses a debug signing configuration for
local development. Configure your own release signing before publishing the
example as a production app. Do not include keys or signing passwords in the
plugin repository.

1. Enable internal app sharing as required by Google Play for your test device
   and account. Use the same tester account throughout.
2. Build the older example with the native plugin enabled (no `UPDATE_DEMO`):

   ```sh
   cd example
   flutter build appbundle --release --build-name=1.0.0 --build-number=10 --dart-define=EXAMPLE_BUILD=10
   ```

3. Upload it through Play Console's internal app sharing and install it from its
   sharing URL. Confirm the home screen says GOOGLE PLAY MODE and Example build 10.
4. Build the newer version:

   ```sh
   flutter build appbundle --release --build-name=1.0.1 --build-number=11 --dart-define=EXAMPLE_BUILD=11
   ```

5. Upload that bundle through internal app sharing.
6. On the device, open the **newer sharing URL but do not install from the Play
   page**. Return to the older app using its launcher icon.
7. Open a custom update surface. Tap Download update, accept Play's confirmation,
   and wait for the download.
8. Tap Restart and install. Confirm Example build 11 appears after restarting.

If those version codes have already been used in your app, choose higher codes.
For a testing-track release, the newer version must be available to the same
opted-in tester. Disable app auto-update temporarily if it updates the old build
before you can exercise the in-app flow.

Source: [Google's internal app sharing workflow](https://developer.android.com/guide/playcore/in-app-updates/test).

## Device cases to verify before publishing the plugin

- Accept and reject the Play consent prompt.
- Show real byte progress while downloading.
- Close and reopen each custom UI presentation during download.
- Background and resume the app during and after download.
- Rotate the device while consent or download is in progress.
- Relaunch the app after a downloaded update; recover the install action.
- Tap Download or Restart repeatedly; no duplicate flows.
- Simulate a lost connection and retry when the connection returns.
- Install and verify the new version actually runs.
- Verify no-update and ineligible-account behavior.

Record Android version, Flutter version, installed/update version codes, and
outcomes. The local demo and unit tests supplement this device test.
