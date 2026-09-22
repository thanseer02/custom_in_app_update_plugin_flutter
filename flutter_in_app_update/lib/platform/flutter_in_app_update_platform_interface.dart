import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_in_app_update_method_channel.dart';

abstract class FlutterInAppUpdatePlatform extends PlatformInterface {
  /// Constructs a FlutterInAppUpdatePlatform.
  FlutterInAppUpdatePlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterInAppUpdatePlatform _instance = MethodChannelFlutterInAppUpdate();

  /// The default instance of [FlutterInAppUpdatePlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterInAppUpdate].
  static FlutterInAppUpdatePlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterInAppUpdatePlatform] when
  /// they register themselves.
  static set instance(FlutterInAppUpdatePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
