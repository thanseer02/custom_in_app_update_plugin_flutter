import 'package:flutter/services.dart';
import 'in_app_update_exception.dart';

/// Centralized utility for mapping underlying exceptions to `InAppUpdateException`.
class ErrorMapper {
  /// Maps a native `PlatformException` to a stable `InAppUpdateException`.
  static InAppUpdateException mapPlatformException(PlatformException e) {
    final code = _mapCode(e.code);
    return InAppUpdateException(
      code,
      _getUserFriendlyMessage(code, e.message),
      e,
    );
  }

  /// Maps generic dart errors (e.g., from network operations) to `InAppUpdateException`.
  static InAppUpdateException mapGenericError(Object e, [StackTrace? stackTrace]) {
    if (e is InAppUpdateException) return e;

    return InAppUpdateException(
      InAppUpdateErrorCode.unknownError,
      'An unexpected error occurred during the update process.',
      e,
    );
  }

  static InAppUpdateErrorCode _mapCode(String platformCode) {
    switch (platformCode.toUpperCase()) {
      case 'UNAVAILABLE':
        return InAppUpdateErrorCode.updateUnavailable;
      case 'STORE_UNAVAILABLE':
        return InAppUpdateErrorCode.storeUnavailable;
      case 'ACTIVITY_UNAVAILABLE':
        return InAppUpdateErrorCode.activityUnavailable;
      case 'CANCELED':
        return InAppUpdateErrorCode.updateCanceled;
      case 'FAILED':
        return InAppUpdateErrorCode.updateFailed;
      case 'ALREADY_RUNNING':
        return InAppUpdateErrorCode.updateAlreadyRunning;
      case 'INVALID_VERSION':
        return InAppUpdateErrorCode.invalidVersion;
      case 'UNSUPPORTED_PLATFORM':
        return InAppUpdateErrorCode.unsupportedPlatform;
      case 'UNSUPPORTED_UPDATE_TYPE':
        return InAppUpdateErrorCode.unsupportedUpdateType;
      default:
        return InAppUpdateErrorCode.unknownError;
    }
  }

  static String _getUserFriendlyMessage(InAppUpdateErrorCode code, String? originalMessage) {
    switch (code) {
      case InAppUpdateErrorCode.updateUnavailable:
        return 'No update is currently available.';
      case InAppUpdateErrorCode.storeUnavailable:
        return 'The app store service is currently unavailable or unreachable.';
      case InAppUpdateErrorCode.activityUnavailable:
        return 'Unable to launch the update flow UI.';
      case InAppUpdateErrorCode.updateCanceled:
        return 'The update was canceled by the user.';
      case InAppUpdateErrorCode.updateFailed:
        return 'The update process failed.';
      case InAppUpdateErrorCode.updateAlreadyRunning:
        return 'An update process is already currently running.';
      case InAppUpdateErrorCode.invalidVersion:
        return 'The provided version information is invalid.';
      case InAppUpdateErrorCode.unsupportedPlatform:
        return 'In-app updates are not supported on this platform.';
      case InAppUpdateErrorCode.unsupportedUpdateType:
        return 'The requested update type is not supported.';
      case InAppUpdateErrorCode.networkError:
        return 'A network error occurred while checking for updates.';
      case InAppUpdateErrorCode.timeout:
        return 'The request to check for updates timed out.';
      case InAppUpdateErrorCode.invalidConfiguration:
        return 'The configuration provided for the update is invalid.';
      case InAppUpdateErrorCode.unknownError:
      default:
        return originalMessage ?? 'An unknown error occurred during the update process.';
    }
  }
}
