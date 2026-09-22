import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'my_in_app_update_method_channel.dart';
import 'src/models/download_progress.dart';
import 'src/models/update_info.dart';

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

  /// Stream of download progress updates for flexible in-app updates.
  Stream<DownloadProgress> get downloadProgressStream {
    throw UnimplementedError('downloadProgressStream has not been implemented.');
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  /// Checks if an update is available on the platform store.
  Future<UpdateInfo> checkForUpdate() {
    throw UnimplementedError('checkForUpdate() has not been implemented.');
  }

  /// Starts an immediate (full-screen blocking) update flow.
  Future<void> startImmediateUpdate() {
    throw UnimplementedError('startImmediateUpdate() has not been implemented.');
  }

  /// Starts an immediate update flow (alias for [startImmediateUpdate]).
  Future<void> performImmediateUpdate() => startImmediateUpdate();

  /// Starts a flexible (background download) update flow.
  Future<void> startFlexibleUpdate({
    void Function(UpdateInfo updateInfo)? onProgress,
  }) {
    throw UnimplementedError('startFlexibleUpdate() has not been implemented.');
  }

  /// Completes a flexible update by installing the downloaded update and restarting the app.
  Future<void> completeFlexibleUpdate() {
    throw UnimplementedError('completeFlexibleUpdate() has not been implemented.');
  }
}
