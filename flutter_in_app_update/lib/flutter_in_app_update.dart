import 'package:flutter/services.dart';
import 'enums/update_install_status.dart';
import 'models/update_info.dart';

export 'enums/update_availability.dart';
export 'enums/update_install_status.dart';
export 'enums/update_type.dart';
export 'models/in_app_update_config.dart';
export 'models/update_info.dart';
export 'services/version_comparator.dart';
export 'enums/update_policy.dart';
export 'models/update_decision.dart';
export 'services/update_decision_engine.dart';
/// The main entry point for the `flutter_in_app_update` plugin.
class FlutterInAppUpdate {
  static const MethodChannel _channel = MethodChannel('flutter_in_app_update');
  static const EventChannel _eventChannel = EventChannel('flutter_in_app_update_events');

  Future<String?> getPlatformVersion() async {
    return _channel.invokeMethod<String>('getPlatformVersion');
  }

  /// Checks if an update is available on the respective store.
  /// 
  /// Returns an [UpdateInfo] object containing the available version, current
  /// version, and update status.
  static Future<UpdateInfo> checkForUpdate() async {
    final result = await _channel.invokeMapMethod<String, dynamic>('checkForUpdate');
    if (result == null) {
      throw PlatformException(
        code: 'UNAVAILABLE',
        message: 'Could not fetch update info',
      );
    }
    return UpdateInfo.fromJson(result);
  }

  /// Retrieves the cached update info if already checked, otherwise fetches it.
  static Future<UpdateInfo> getUpdateInfo() async {
    return checkForUpdate();
  }

  /// Starts a flexible update flow.
  /// 
  /// Only supported on Android. Throws a [PlatformException] on iOS.
  static Future<void> startFlexibleUpdate() async {
    await _channel.invokeMethod('startFlexibleUpdate');
  }

  /// Starts an immediate update flow.
  /// 
  /// Only supported on Android. Throws a [PlatformException] on iOS.
  static Future<void> startImmediateUpdate() async {
    await _channel.invokeMethod('startImmediateUpdate');
  }

  /// Completes a flexible update that has been downloaded.
  /// 
  /// Only supported on Android. Throws a [PlatformException] on iOS.
  static Future<void> completeFlexibleUpdate() async {
    await _channel.invokeMethod('completeFlexibleUpdate');
  }

  /// Opens the app's store page (Play Store / App Store).
  static Future<void> openStore() async {
    await _channel.invokeMethod('openStore');
  }

  /// Stream to listen to update install status (useful for tracking flexible 
  /// update progress on Android).
  static Stream<UpdateInstallStatus> get installStatusStream {
    return _eventChannel.receiveBroadcastStream().map((dynamic event) {
      if (event is int) {
        if (event >= 0 && event < UpdateInstallStatus.values.length) {
          return UpdateInstallStatus.values[event];
        }
      }
      return UpdateInstallStatus.unknown;
    });
  }
}
