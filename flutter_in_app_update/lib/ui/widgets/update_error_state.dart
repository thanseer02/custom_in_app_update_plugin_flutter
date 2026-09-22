import 'package:flutter/material.dart';

/// A customizable widget to display when an update check or installation fails.
class UpdateErrorState extends StatelessWidget {
  /// The error message to display.
  final String errorMessage;

  /// Optional callback to retry the failed operation.
  final VoidCallback? onRetry;

  /// Custom text for the retry button.
  final String retryButtonText;

  /// Custom icon to display above the error message.
  final IconData errorIcon;

  /// Color for the error icon.
  final Color? iconColor;

  /// Text style for the error message.
  final TextStyle? messageStyle;

  /// Button style for the retry button.
  final ButtonStyle? retryButtonStyle;

  /// An optional custom builder to completely override the UI.
  final Widget Function(BuildContext context, String error, VoidCallback? onRetry)? customBuilder;

  const UpdateErrorState({
    super.key,
    this.errorMessage = 'An error occurred while checking for updates.',
    this.onRetry,
    this.retryButtonText = 'Try Again',
    this.errorIcon = Icons.error_outline,
    this.iconColor = Colors.red,
    this.messageStyle,
    this.retryButtonStyle,
    this.customBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (customBuilder != null) {
      return customBuilder!(context, errorMessage, onRetry);
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              errorIcon,
              size: 48,
              color: iconColor,
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: messageStyle ?? Theme.of(context).textTheme.bodyLarge,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onRetry,
                style: retryButtonStyle,
                child: Text(retryButtonText),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
