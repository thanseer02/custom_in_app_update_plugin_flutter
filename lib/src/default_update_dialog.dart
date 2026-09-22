import 'package:flutter/material.dart';
import 'update_info.dart';

/// Simple fallback dialog used when the consumer doesn't pass a custom
/// `uiBuilder` to `CustomInAppUpdate.checkForUpdate`. Kept intentionally
/// plain — the whole point of this plugin is that most apps will supply
/// their own.
void showDefaultUpdateDialog(
  BuildContext context,
  UpdateInfo info,
  VoidCallback onUpdate,
  VoidCallback onDismiss,
) {
  showDialog<void>(
    context: context,
    barrierDismissible: !info.immediateAllowed,
    builder: (context) {
      return AlertDialog(
        title: const Text('Update available'),
        content: Text(
          info.availableVersion != null
              ? 'A new version (${info.availableVersion}) is available.'
              : 'A new version of the app is available.',
        ),
        actions: [
          if (!info.immediateAllowed)
            TextButton(
              onPressed: onDismiss,
              child: const Text('Later'),
            ),
          FilledButton(
            onPressed: onUpdate,
            child: const Text('Update'),
          ),
        ],
      );
    },
  );
}
