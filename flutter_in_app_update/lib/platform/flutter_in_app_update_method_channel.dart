import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/update_info.dart';
import 'flutter_in_app_update_platform_interface.dart';

/// An implementation of [FlutterInAppUpdatePlatform] that uses method channels.
class MethodChannelFlutterInAppUpdate extends FlutterInAppUpdatePlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_in_app_update');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<UpdateInfo> checkForUpdate() async {
    throw UnimplementedError('checkForUpdate() has not been implemented.');
  }

  @override
  Future<void> startFlexibleUpdate() async {
    throw UnimplementedError('startFlexibleUpdate() has not been implemented.');
  }

  @override
  Future<void> startImmediateUpdate() async {
    throw UnimplementedError('startImmediateUpdate() has not been implemented.');
  }

  @override
  Future<void> completeFlexibleUpdate() async {
    throw UnimplementedError('completeFlexibleUpdate() has not been implemented.');
  }

  @override
  Future<void> openStore() async {
    throw UnimplementedError('openStore() has not been implemented.');
  }

  @override
  Future<UpdateInfo> getUpdateInfo() async {
    throw UnimplementedError('getUpdateInfo() has not been implemented.');
  }
}
