import 'package:flutter/material.dart';
import '../../enums/update_install_status.dart';

/// A widget that displays a progress bar during a flexible update.
class FlexibleUpdateProgressBar extends StatelessWidget {
  /// The stream of update installation status (e.g. from FlutterInAppUpdate.installStatusStream).
  final Stream<UpdateInstallStatus> statusStream;

  /// Optional text to show above or beside the progress bar.
  final String? labelText;

  /// Custom text style for the label.
  final TextStyle? labelTextStyle;

  /// The color of the progress indicator.
  final Color? progressColor;

  /// Background color of the progress track.
  final Color? trackColor;

  /// An optional builder to completely customize the UI based on the status.
  final Widget Function(BuildContext context, UpdateInstallStatus status)? customBuilder;

  const FlexibleUpdateProgressBar({
    super.key,
    required this.statusStream,
    this.labelText,
    this.labelTextStyle,
    this.progressColor,
    this.trackColor,
    this.customBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UpdateInstallStatus>(
      stream: statusStream,
      builder: (context, snapshot) {
        final status = snapshot.data ?? UpdateInstallStatus.unknown;

        if (customBuilder != null) {
          return customBuilder!(context, status);
        }

        if (status == UpdateInstallStatus.unknown ||
            status == UpdateInstallStatus.failed ||
            status == UpdateInstallStatus.canceled) {
          return const SizedBox.shrink();
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (labelText != null) ...[
              Text(
                labelText!,
                style: labelTextStyle ?? Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
            ],
            LinearProgressIndicator(
              value: status == UpdateInstallStatus.downloading ? null : 1.0,
              backgroundColor: trackColor,
              color: progressColor,
            ),
            const SizedBox(height: 4),
            Text(
              _getStatusText(status),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        );
      },
    );
  }

  String _getStatusText(UpdateInstallStatus status) {
    switch (status) {
      case UpdateInstallStatus.pending:
        return 'Pending...';
      case UpdateInstallStatus.downloading:
        return 'Downloading update...';
      case UpdateInstallStatus.downloaded:
        return 'Ready to install';
      case UpdateInstallStatus.installing:
        return 'Installing...';
      case UpdateInstallStatus.installed:
        return 'Installed';
      default:
        return '';
    }
  }
}
