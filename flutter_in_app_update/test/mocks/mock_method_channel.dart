import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Helper to setup and teardown mock MethodChannel handlers for [FlutterInAppUpdate].
class MockMethodChannel {
  static const MethodChannel channel = MethodChannel('flutter_in_app_update');
  static const EventChannel eventChannel = EventChannel('flutter_in_app_update_events');

  /// Sets up a custom handler for method channel calls.
  static void setHandler(Future<dynamic>? Function(MethodCall methodCall)? handler) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, handler);
  }

  /// Sets up a standard success response for `checkForUpdate`.
  static void setUpdateAvailableResponse({
    bool isUpdateAvailable = true,
    String currentVersion = '1.0.0',
    String availableVersion = '2.0.0',
    int currentBuildNumber = 1,
    int availableBuildNumber = 2,
    bool immediateUpdateAllowed = true,
    bool flexibleUpdateAllowed = true,
    int updatePriority = 3,
    int clientVersionStalenessDays = 10,
    int installStatus = 1, // pending / downloading / downloaded
    int availability = 2, // updateAvailable
    String platform = 'android',
  }) {
    setHandler((MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'checkForUpdate':
          return {
            'isUpdateAvailable': isUpdateAvailable,
            'currentVersion': currentVersion,
            'availableVersion': availableVersion,
            'currentBuildNumber': currentBuildNumber,
            'availableBuildNumber': availableBuildNumber,
            'immediateUpdateAllowed': immediateUpdateAllowed,
            'flexibleUpdateAllowed': flexibleUpdateAllowed,
            'updatePriority': updatePriority,
            'clientVersionStalenessDays': clientVersionStalenessDays,
            'installStatus': installStatus,
            'availability': availability,
            'platform': platform,
          };
        case 'startFlexibleUpdate':
        case 'startImmediateUpdate':
        case 'completeFlexibleUpdate':
        case 'openStore':
          return null;
        default:
          return null;
      }
    });
  }

  /// Sets up a platform exception throwing handler.
  static void setPlatformErrorResponse({
    required String code,
    String? message,
    dynamic details,
  }) {
    setHandler((MethodCall methodCall) async {
      throw PlatformException(
        code: code,
        message: message,
        details: details,
      );
    });
  }

  /// Clears the handler.
  static void reset() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  }
}
