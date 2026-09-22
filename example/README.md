# custom_app_update example

This is the runnable Android app for the plugin in the parent directory.

```sh
flutter pub get
flutter run --dart-define=UPDATE_DEMO=true
```

Demo mode shows simulated progress without downloading or installing an app.
Choose Success, Cancel, Download fails, or Install fails, then open a bottom
sheet, dialog, or full screen. All three share the same controller.

For a real update, omit the demo flag and follow [the Play testing instructions](../TESTING.md).
Configure your own application ID and signing for Play distribution.

- [Example UI and controller ownership](lib/main.dart)
- [Example-only simulation](lib/demo_update_backend.dart)
- [Plugin README](../README.md)
