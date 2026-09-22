import 'package:flutter/material.dart';

/// Helper to display a notification when a flexible update is downloaded.
class UpdateDownloadedSnackBar {
  /// Shows a standard Material SnackBar indicating the update is ready to install.
  /// 
  /// [onInstall] should typically call `FlutterInAppUpdate.completeFlexibleUpdate()`.
  static void show(
    BuildContext context, {
    required VoidCallback onInstall,
    String message = 'An update has just been downloaded.',
    String actionLabel = 'RESTART',
    Duration duration = const Duration(days: 365), // practically infinite until dismissed/acted upon
    Color? backgroundColor,
    Color? actionTextColor,
    TextStyle? messageStyle,
  }) {
    final snackBar = SnackBar(
      content: Text(
        message,
        style: messageStyle,
      ),
      backgroundColor: backgroundColor,
      duration: duration,
      action: SnackBarAction(
        label: actionLabel,
        textColor: actionTextColor,
        onPressed: onInstall,
      ),
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }
}
