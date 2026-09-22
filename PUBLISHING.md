# Publishing to pub.dev

This repository is a Flutter **plugin**, with a separate runnable app under
`example/`. Publish from the root containing the plugin's `pubspec.yaml`, not from
`example/`. The example has `publish_to: none`; the plugin does not.

## Prepare the first release

1. Complete [TESTING.md](TESTING.md), including a real Play download and restart.
2. Confirm `custom_app_update` is available to your pub.dev account, or choose a
   name you own. If renaming, update the root and example pubspecs, Dart imports,
   documentation, and tests consistently. No name has been reserved by this work.
3. Verify the configured `repository` URL points to the source you intend to
   publish: `https://github.com/thanseer02/custom_in_app_update_plugin_flutter`.
   It was taken from this checkout's Git remote. Add an `issue_tracker` or
   `homepage` only if you have those pages. Push your reviewed source when ready.
4. Review the BSD-3-Clause license and copyright attribution for your release.
5. Set the version and update CHANGELOG.md. The current development prerelease
   is `0.2.0-dev.1`; choose a stable version when device testing is complete.
6. Commit the reviewed source changes. Do not commit signing keys, local SDK
   paths, generated build output, or package caches.

## Validate the exact upload

```sh
flutter pub get
flutter analyze
flutter test
cd example
flutter test
flutter build apk --debug --dart-define=UPDATE_DEMO=true
cd ..
dart pub publish --dry-run
```

Inspect the upload file list and address validation warnings. `.pubignore`
excludes build artifacts, local configuration, signing files, caches, and lock
files. Keep the plugin Android library and example source in the upload.

If the checkout reports tracked IDE files that are now ignored, remove those
IDE files from Git tracking while keeping them locally. Commit the intended
source changes before the final dry run. See VALIDATION.md for the checks already
completed.

A dry run does not upload the package or reserve its name. Static validation
cannot prove the real Google Play update works. The recorded results in
VALIDATION.md describe which checks have actually run.

## Publish after testing

Run this command yourself when you are ready:

```sh
dart pub publish
```

Follow pub's account authentication and confirmation steps. This project setup
has not run that command without `--dry-run` and has not published anything.

After publication, verify the package page, example tab, platform label, README,
and API documentation. Test installing the hosted version into a clean Flutter
app. Add screenshots or a short demo to the README once you have device results.

Reference: [Dart package publishing](https://dart.dev/tools/pub/publishing).
