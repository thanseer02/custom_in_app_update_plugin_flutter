import 'models/update_info.dart';
import 'models/in_app_update_config.dart';
import 'platform/flutter_in_app_update_platform_interface.dart';

export 'enums/update_availability.dart';
export 'enums/update_install_status.dart';
export 'enums/update_type.dart';
export 'models/update_info.dart';
export 'models/in_app_update_config.dart';

/// The main entry point for the Flutter In-App Update plugin.
/// 
/// Provides methods to check for updates and start flexible or immediate updates.
class FlutterInAppUpdate {
  /// Returns the underlying platform version.
  Future<String?> getPlatformVersion() {
    return FlutterInAppUpdatePlatform.instance.getPlatformVersion();
  }

  /// Checks if there is an update available.
  /// 
  /// Returns an [UpdateInfo] object containing details about the availability,
  /// priority, and allowed update types.
  Future<UpdateInfo> checkForUpdate() {
    return FlutterInAppUpdatePlatform.instance.checkForUpdate();
  }

  /// Starts a flexible update.
  /// 
  /// A flexible update downloads in the background while the user continues
  /// using the app. Once downloaded, you must call [completeFlexibleUpdate]
  /// to prompt the user to restart the app and install the update.
  Future<void> startFlexibleUpdate() {
    return FlutterInAppUpdatePlatform.instance.startFlexibleUpdate();
  }

  /// Starts an immediate update.
  /// 
  /// An immediate update blocks the user from using the app until the
  /// download and installation are complete.
  Future<void> startImmediateUpdate() {
    return FlutterInAppUpdatePlatform.instance.startImmediateUpdate();
  }

  /// Completes a flexible update that has been downloaded.
  /// 
  /// This will prompt the user to restart the app to apply the update.
  Future<void> completeFlexibleUpdate() {
    return FlutterInAppUpdatePlatform.instance.completeFlexibleUpdate();
  }

  /// Opens the app store page for the current application.
  /// 
  /// Useful as a fallback if in-app updates are not supported or fail.
  Future<void> openStore() {
    return FlutterInAppUpdatePlatform.instance.openStore();
  }

  /// Retrieves the current update information without triggering a new check.
  /// 
  /// Useful to get the current installation status (e.g., if a flexible update
  /// is currently downloading).
  Future<UpdateInfo> getUpdateInfo() {
    return FlutterInAppUpdatePlatform.instance.getUpdateInfo();
  }
}
