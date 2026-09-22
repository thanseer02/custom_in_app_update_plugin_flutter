import 'package:flutter/widgets.dart';
import '../models/update_info.dart';

/// Signature for a custom UI builder function that constructs the update prompt.
///
/// - [context]: The current [BuildContext].
/// - [info]: Metadata describing the available update.
/// - [onUpdate]: Callback to initiate the update process.
/// - [onDismiss]: Callback to dismiss the update prompt.
typedef UpdateUIBuilder = Widget Function(
  BuildContext context,
  UpdateInfo info,
  VoidCallback onUpdate,
  VoidCallback onDismiss,
);
