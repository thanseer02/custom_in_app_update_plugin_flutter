import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_in_app_update_platform_interface.dart';

/// An implementation of [FlutterInAppUpdatePlatform] that uses method channels.
class MethodChannelFlutterInAppUpdate extends FlutterInAppUpdatePlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_in_app_update');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }
}
