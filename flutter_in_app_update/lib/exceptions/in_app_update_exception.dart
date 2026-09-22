/// Stable error codes for all potential failure points during an in-app update.
enum InAppUpdateErrorCode {
  /// The requested update is not available.
  updateUnavailable,

  /// A network error occurred while checking for or downloading an update.
  networkError,

  /// A network request timed out.
  timeout,

  /// The underlying app store (Google Play/App Store) is unavailable or unresponsive.
  storeUnavailable,

  /// The required activity or view controller is not available to display the UI.
  activityUnavailable,

  /// The user canceled the update flow.
  updateCanceled,

  /// The update process failed for an unspecified reason.
  updateFailed,

  /// The version string provided was invalid or malformed.
  invalidVersion,

  /// The configuration provided for the update is invalid.
  invalidConfiguration,

  /// The current platform is not supported by this operation.
  unsupportedPlatform,

  /// The requested update type (flexible/immediate) is not supported for this update.
  unsupportedUpdateType,

  /// An update flow is already running and cannot be started again.
  updateAlreadyRunning,

  /// An unknown error occurred.
  unknownError,
}

/// A unified exception for all errors thrown by the `flutter_in_app_update` plugin.
class InAppUpdateException implements Exception {
  /// The stable error code identifying the type of failure.
  final InAppUpdateErrorCode code;

  /// A developer-friendly message describing the error.
  final String message;

  /// The original underlying error (e.g., PlatformException, SocketException), useful for debugging.
  /// 
  /// This should generally not be exposed to end users.
  final Object? originalError;

  const InAppUpdateException(
    this.code,
    this.message, [
    this.originalError,
  ]);

  @override
  String toString() {
    if (originalError != null) {
      return 'InAppUpdateException($code): $message\nOriginal error: $originalError';
    }
    return 'InAppUpdateException($code): $message';
  }
}
