import 'dart:io';

import 'package:flutter/services.dart';
import 'enums/update_availability.dart';
import 'enums/update_install_status.dart';
import 'enums/update_source.dart';
import 'models/update_info.dart';
import 'models/in_app_update_config.dart';
import 'services/remote_update_service.dart';
import 'services/version_comparator.dart';

export 'enums/update_availability.dart';
export 'enums/update_install_status.dart';
export 'enums/update_source.dart';
export 'enums/update_type.dart';
export 'models/in_app_update_config.dart';
export 'models/remote_update_response.dart';
export 'models/update_info.dart';
export 'services/version_comparator.dart';
export 'enums/update_policy.dart';
export 'models/update_decision.dart';
export 'services/update_decision_engine.dart';
export 'services/remote_update_service.dart';
export 'exceptions/in_app_update_exception.dart';
export 'exceptions/error_mapper.dart';

import 'exceptions/in_app_update_exception.dart';
import 'exceptions/error_mapper.dart';

/// The main entry point for the `flutter_in_app_update` plugin.
class FlutterInAppUpdate {
  static const MethodChannel _channel = MethodChannel('flutter_in_app_update');
  static const EventChannel _eventChannel = EventChannel('flutter_in_app_update_events');

  static InAppUpdateConfig? _config;
  static RemoteUpdateService? _remoteUpdateService;

  /// Initializes the plugin with the provided configuration.
  static Future<void> initialize({required InAppUpdateConfig config}) async {
    _config = config;
    if (config.source == UpdateSource.remote) {
      _remoteUpdateService = RemoteUpdateService();
    }
  }

  Future<String?> getPlatformVersion() async {
    try {
      return await _channel.invokeMethod<String>('getPlatformVersion');
    } on PlatformException catch (e) {
      throw ErrorMapper.mapPlatformException(e);
    } catch (e) {
      throw ErrorMapper.mapGenericError(e);
    }
  }

  /// Checks if an update is available based on the configured source.
  /// 
  /// Returns an [UpdateInfo] object containing the available version, current
  /// version, and update status.
  static Future<UpdateInfo> checkForUpdate() async {
    Map<String, dynamic>? result;
    try {
      result = await _channel.invokeMapMethod<String, dynamic>('checkForUpdate');
    } on PlatformException catch (e) {
      throw ErrorMapper.mapPlatformException(e);
    } catch (e) {
      throw ErrorMapper.mapGenericError(e);
    }

    if (result == null) {
      throw const InAppUpdateException(
        InAppUpdateErrorCode.updateFailed,
        'Could not fetch native update info',
      );
    }
    
    var nativeInfo = UpdateInfo.fromJson(result);
    final config = _config;

    if (config != null && config.source == UpdateSource.remote && _remoteUpdateService != null) {
      try {
        final remoteResponse = await _remoteUpdateService!.fetchUpdateConfig(config);
        final platformData = Platform.isIOS ? remoteResponse.ios : remoteResponse.android;
        
        if (platformData != null) {
          final isUpdateAvailable = VersionComparator.isUpdateAvailable(
            nativeInfo.currentVersion, 
            platformData.latestVersion,
          );
          
          nativeInfo = UpdateInfo(
            isUpdateAvailable: isUpdateAvailable,
            currentVersion: nativeInfo.currentVersion,
            availableVersion: platformData.latestVersion,
            currentBuildNumber: nativeInfo.currentBuildNumber,
            availableBuildNumber: nativeInfo.availableBuildNumber,
            immediateUpdateAllowed: isUpdateAvailable,
            flexibleUpdateAllowed: isUpdateAvailable,
            updatePriority: nativeInfo.updatePriority,
            clientVersionStalenessDays: nativeInfo.clientVersionStalenessDays,
            installStatus: nativeInfo.installStatus,
            availability: isUpdateAvailable 
                ? UpdateAvailability.updateAvailable 
                : UpdateAvailability.noUpdate,
            platform: nativeInfo.platform,
          );
        }
      } catch (e) {
        // If remote fetch fails and no cache is available, we fall back to native info
        // or throw an error based on the application's needs. For now, we fall back.
      }
    }

    return nativeInfo;
  }

  /// Retrieves the cached update info if already checked, otherwise fetches it.
  static Future<UpdateInfo> getUpdateInfo() async {
    return checkForUpdate();
  }

  /// Starts a flexible update flow.
  /// 
  /// Only supported on Android. Throws a [InAppUpdateException] on iOS.
  static Future<void> startFlexibleUpdate() async {
    try {
      await _channel.invokeMethod('startFlexibleUpdate');
    } on PlatformException catch (e) {
      throw ErrorMapper.mapPlatformException(e);
    } catch (e) {
      throw ErrorMapper.mapGenericError(e);
    }
  }

  /// Starts an immediate update flow.
  /// 
  /// Only supported on Android. Throws a [InAppUpdateException] on iOS.
  static Future<void> startImmediateUpdate() async {
    try {
      await _channel.invokeMethod('startImmediateUpdate');
    } on PlatformException catch (e) {
      throw ErrorMapper.mapPlatformException(e);
    } catch (e) {
      throw ErrorMapper.mapGenericError(e);
    }
  }

  /// Completes a flexible update that has been downloaded.
  /// 
  /// Only supported on Android. Throws a [InAppUpdateException] on iOS.
  static Future<void> completeFlexibleUpdate() async {
    try {
      await _channel.invokeMethod('completeFlexibleUpdate');
    } on PlatformException catch (e) {
      throw ErrorMapper.mapPlatformException(e);
    } catch (e) {
      throw ErrorMapper.mapGenericError(e);
    }
  }

  /// Opens the app's store page (Play Store / App Store).
  static Future<void> openStore() async {
    try {
      await _channel.invokeMethod('openStore');
    } on PlatformException catch (e) {
      throw ErrorMapper.mapPlatformException(e);
    } catch (e) {
      throw ErrorMapper.mapGenericError(e);
    }
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
