import 'package:flutter/material.dart';
import '../../models/update_info.dart';
import '../models/update_dialog_style.dart';

/// A customizable dialog for prompting the user to update the app.
class InAppUpdateDialog extends StatelessWidget {
  /// Information about the available update.
  final UpdateInfo updateInfo;

  /// Callback when the user chooses to update.
  final VoidCallback onUpdate;

  /// Callback when the user chooses to update later.
  /// If null, the dialog is considered mandatory and the "Later" button is hidden.
  final VoidCallback? onLater;

  /// Styling options for the dialog.
  final UpdateDialogStyle? style;

  /// Whether the dialog can be dismissed by tapping outside.
  final bool isDismissible;

  /// An optional custom builder to completely override the dialog UI.
  final Widget Function(BuildContext context, UpdateInfo updateInfo)? customBuilder;

  const InAppUpdateDialog({
    Key? key,
    required this.updateInfo,
    required this.onUpdate,
    this.onLater,
    this.style,
    this.isDismissible = false,
    this.customBuilder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (customBuilder != null) {
      return customBuilder!(context, updateInfo);
    }

    final isMandatory = onLater == null;
    final defaultTitle = isMandatory ? 'Update Required' : 'Update Available';
    final defaultDesc = 'A new version (${updateInfo.availableVersion}) of the app is available. Please update to the latest version to continue.';

    return PopScope(
      canPop: !isMandatory && isDismissible,
      child: AlertDialog(
        backgroundColor: style?.backgroundColor,
        title: Text(
          style?.title ?? defaultTitle,
          style: style?.titleStyle,
        ),
        content: Text(
          style?.description ?? defaultDesc,
          style: style?.descriptionStyle,
        ),
        actions: [
          if (!isMandatory)
            TextButton(
              onPressed: onLater,
              style: style?.laterButtonStyle,
              child: Text(style?.laterButtonText ?? 'Later'),
            ),
          ElevatedButton(
            onPressed: onUpdate,
            style: style?.updateButtonStyle,
            child: Text(style?.updateButtonText ?? 'Update Now'),
          ),
        ],
      ),
    );
  }
}
