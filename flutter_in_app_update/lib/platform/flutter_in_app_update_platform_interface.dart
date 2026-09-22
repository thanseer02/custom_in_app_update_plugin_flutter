import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import '../models/update_info.dart';

/// The interface that implementations of flutter_in_app_update must implement.
///
/// Platform implementations should extend this class rather than implement it as `flutter_in_app_update`
/// does not consider newly added methods to be breaking changes. Extending this class
/// (using `extends`) ensures that the subclass will get the default implementation, while
/// platform implementations that `implements` this interface will be broken by newly added
/// [FlutterInAppUpdatePlatform] methods.
abstract class FlutterInAppUpdatePlatform extends PlatformInterface {
  /// Constructs a FlutterInAppUpdatePlatform.
  FlutterInAppUpdatePlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterInAppUpdatePlatform _instance = _PlaceholderImplementation();

  /// The default instance of [FlutterInAppUpdatePlatform] to use.
  ///
  /// Defaults to [_PlaceholderImplementation].
  static FlutterInAppUpdatePlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterInAppUpdatePlatform] when
  /// they register themselves.
  static set instance(FlutterInAppUpdatePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Returns the platform version.
  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  /// Checks for an available update and returns an [UpdateInfo] object.
  Future<UpdateInfo> checkForUpdate() {
    throw UnimplementedError('checkForUpdate() has not been implemented.');
  }

  /// Starts a flexible update (downloads in background).
  Future<void> startFlexibleUpdate() {
    throw UnimplementedError('startFlexibleUpdate() has not been implemented.');
  }

  /// Starts an immediate update (blocks user interaction until installed).
  Future<void> startImmediateUpdate() {
    throw UnimplementedError('startImmediateUpdate() has not been implemented.');
  }

  /// Completes a flexible update (prompts user to install after download finishes).
  Future<void> completeFlexibleUpdate() {
    throw UnimplementedError('completeFlexibleUpdate() has not been implemented.');
  }

  /// Opens the relevant app store page for the application.
  Future<void> openStore() {
    throw UnimplementedError('openStore() has not been implemented.');
  }

  /// Gets the current update info if available without triggering a new network check.
  Future<UpdateInfo> getUpdateInfo() {
    throw UnimplementedError('getUpdateInfo() has not been implemented.');
  }
}

class _PlaceholderImplementation extends FlutterInAppUpdatePlatform {}
