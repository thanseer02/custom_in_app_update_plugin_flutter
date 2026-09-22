# Validation record

Validated on 2026-09-22 with Flutter 3.41.2 / Dart 3.11.0 on macOS.

| Check | Result |
| --- | --- |
| Dart formatting | Passed; no changes needed |
| `flutter analyze` | Passed; no issues |
| Root `flutter test` | 16 controller and platform-channel tests passed |
| Example `flutter test` | 2 widget tests passed |
| Android debug APK build with `UPDATE_DEMO=true` | Passed, including native Kotlin compilation |
| `dart pub publish --dry-run` in a clean source copy | Passed; 0 warnings |
| Third-party update package imports/dependency | Removed |

The checked-out repository's publish dry run also reported Git hygiene warnings:
tracked IDE files are now ignored, and source changes are uncommitted. The clean
release copy excludes IDE files and validates without warnings. No Git staging
or commits were changed by the release-validation step.

The APK is a demo build: it simulates update progress and installation. The
Android plugin is compiled into it, but demo mode does not call Google Play.

## Still required before publication

- Real Google Play consent, download, installation, and restart on a device.
- Device checks listed in TESTING.md, including lifecycle and retry behavior.
- Confirm package name availability/ownership and review the chosen license.
- Commit the intended source and clean up tracked IDE files before the final
  publish dry run in your checkout.

Nothing has been uploaded to pub.dev. A successful dry run does not reserve a
package name or guarantee server-side publication approval.
