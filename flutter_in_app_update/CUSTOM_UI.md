# Custom UI Guide for `flutter_in_app_update`

The `flutter_in_app_update` plugin is strictly separated from its UI representation. The UI components provided in `package:flutter_in_app_update/ui.dart` are **completely optional**. 

You are encouraged to build your own custom UI to match your app's design system. Here are two ways to do that:

## Option 1: Completely Custom UI

You can ignore `package:flutter_in_app_update/ui.dart` entirely. Simply use the core `FlutterInAppUpdate` methods and show your own dialogs/widgets based on the returned `UpdateInfo`.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_in_app_update/flutter_in_app_update.dart';

Future<void> checkAndShowCustomUpdateDialog(BuildContext context) async {
  try {
    final updateInfo = await FlutterInAppUpdate.checkForUpdate();
    
    if (updateInfo.isUpdateAvailable) {
      // Show your entirely custom dialog
      showDialog(
        context: context,
        barrierDismissible: !updateInfo.immediateUpdateAllowed,
        builder: (context) {
          return AlertDialog(
            title: Text('New Version: ${updateInfo.availableVersion}'),
            content: const Text('Check out the awesome new features!'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Not Now'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  FlutterInAppUpdate.startFlexibleUpdate();
                },
                child: const Text('Update'),
              )
            ],
          );
        }
      );
    }
  } catch (e) {
    // Handle error (e.g. log it or show a custom error widget)
  }
}
```

## Option 2: Overriding the Built-In Wrapper (`customBuilder`)

If you want to use the built-in widgets to handle the logic of when to show mandatory vs optional states, but want to completely replace the rendered output, you can use the `customBuilder` parameter on the provided widgets.

### Custom Dialog Example

```dart
import 'package:flutter/material.dart';
import 'package:flutter_in_app_update/flutter_in_app_update.dart';
import 'package:flutter_in_app_update/ui.dart';

void showMyDialog(BuildContext context, UpdateInfo updateInfo) {
  showDialog(
    context: context,
    builder: (context) => InAppUpdateDialog(
      updateInfo: updateInfo,
      onUpdate: () => FlutterInAppUpdate.startImmediateUpdate(),
      // Completely replace the AlertDialog with your own widget tree
      customBuilder: (context, info) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(20),
            height: 200,
            child: Column(
              children: [
                Text('Wow! Version ${info.availableVersion} is here!', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                ElevatedButton(
                  onPressed: () => FlutterInAppUpdate.startImmediateUpdate(),
                  child: const Text('GIMME THE UPDATE!'),
                )
              ],
            ),
          ),
        );
      },
    )
  );
}
```

This pattern also applies to `FlexibleUpdateProgressBar` and `UpdateErrorState` which both expose a `customBuilder`.
