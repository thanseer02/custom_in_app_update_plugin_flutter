import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'my_in_app_update_method_channel.dart';

abstract class MyInAppUpdatePlatform extends PlatformInterface {
  /// Constructs a MyInAppUpdatePlatform.
  MyInAppUpdatePlatform() : super(token: _token);

  static final Object _token = Object();

  static MyInAppUpdatePlatform _instance = MethodChannelMyInAppUpdate();

  /// The default instance of [MyInAppUpdatePlatform] to use.
  ///
  /// Defaults to [MethodChannelMyInAppUpdate].
  static MyInAppUpdatePlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [MyInAppUpdatePlatform] when
  /// they register themselves.
  static set instance(MyInAppUpdatePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
