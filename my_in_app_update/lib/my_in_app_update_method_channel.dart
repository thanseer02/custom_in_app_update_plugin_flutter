import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'my_in_app_update_platform_interface.dart';
import 'src/enums/update_availability.dart';
import 'src/models/download_progress.dart';
import 'src/models/update_info.dart';

/// An implementation of [MyInAppUpdatePlatform] that uses method channels.
class MethodChannelMyInAppUpdate extends MyInAppUpdatePlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('my_in_app_update');

  final StreamController<DownloadProgress> _downloadProgressController =
      StreamController<DownloadProgress>.broadcast();

  void Function(UpdateInfo updateInfo)? _onProgressCallback;
  UpdateInfo? _lastKnownInfo;
  bool _isHandlerInitialized = false;

  void _ensureHandlerInitialized() {
    if (!_isHandlerInitialized) {
      methodChannel.setMethodCallHandler(_handleNativeMethodCall);
      _isHandlerInitialized = true;
    }
  }

  @override
  Stream<DownloadProgress> get downloadProgressStream {
    _ensureHandlerInitialized();
    return _downloadProgressController.stream;
  }

  Future<dynamic> _handleNativeMethodCall(MethodCall call) async {
    if (call.method == 'onInstallStateChanged') {
      final arguments = call.arguments as Map<dynamic, dynamic>? ?? {};
      final progress = DownloadProgress.fromMap(arguments);

      _downloadProgressController.add(progress);

      _lastKnownInfo = (_lastKnownInfo ??
              const UpdateInfo(
                versionCode: 0,
                availability: UpdateAvailability.available,
              ))
          .copyWith(
        installStatus: progress.installStatus,
        bytesDownloaded: progress.bytesDownloaded,
        totalBytesToDownload: progress.totalBytesToDownload,
      );

      _onProgressCallback?.call(_lastKnownInfo!);
    }
  }

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }

  @override
  Future<UpdateInfo> checkForUpdate() async {
    final result = await methodChannel.invokeMapMethod<dynamic, dynamic>('checkForUpdate');
    if (result == null) {
      return const UpdateInfo(
        versionCode: 0,
        availability: UpdateAvailability.unknown,
      );
    }
    final info = UpdateInfo.fromMap(result);
    _lastKnownInfo = info;
    return info;
  }

  @override
  Future<void> startImmediateUpdate() async {
    await methodChannel.invokeMethod<void>('startImmediateUpdate');
  }

  @override
  Future<void> startFlexibleUpdate({
    void Function(UpdateInfo updateInfo)? onProgress,
  }) async {
    _ensureHandlerInitialized();
    _onProgressCallback = onProgress;
    await methodChannel.invokeMethod<void>('startFlexibleUpdate');
  }

  @override
  Future<void> completeFlexibleUpdate() async {
    await methodChannel.invokeMethod<void>('completeFlexibleUpdate');
  }
}
