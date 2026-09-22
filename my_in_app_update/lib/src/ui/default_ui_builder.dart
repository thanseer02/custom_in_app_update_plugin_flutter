import 'package:flutter/material.dart';
import '../models/update_info.dart';

/// The default [AlertDialog] update prompt UI provided out-of-the-box by the plugin.
///
/// Consumers who do not pass a custom `uiBuilder` will receive this dialog automatically.
Widget defaultUiBuilder(
  BuildContext context,
  UpdateInfo info,
  VoidCallback onUpdate,
  VoidCallback onDismiss,
) {
  final isFlexible = info.flexibleAllowed && !info.immediateAllowed;

  return AlertDialog(
    title: const Text('Update Available'),
    content: Text(
      'A new version (${info.versionCode}) is available. '
      '${isFlexible ? "You can download it in the background while using the app." : "Please update to continue using the latest features."}',
    ),
    actions: [
      TextButton(
        onPressed: onDismiss,
        child: const Text('Later'),
      ),
      FilledButton(
        onPressed: onUpdate,
        child: Text(isFlexible ? 'Download' : 'Update Now'),
      ),
    ],
  );
}
