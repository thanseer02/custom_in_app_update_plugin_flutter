import 'dart:async';
import 'package:flutter/services.dart';
import 'update_info.dart';

/// Thin wrapper around the native MethodChannel that talks to Google
/// Play's In-App Update API. Not exported publicly — consumers only ever
/// see [UpdateInfo] and the top-level API in `custom_in_app_update.dart`.
class AndroidUpdateChannel {
  AndroidUpdateChannel._();
  static final AndroidUpdateChannel instance = AndroidUpdateChannel._();

  static const MethodChannel _channel =
      MethodChannel('custom_in_app_update');
  static const EventChannel _installStateChannel =
      EventChannel('custom_in_app_update/install_state');

  Stream<UpdateInfo>? _progressStream;

  /// Queries Play Store for update availability. Returns an [UpdateInfo]
  /// built from the native `AppUpdateInfo` payload.
  Future<UpdateInfo> checkForUpdate() async {
    try {
      final result =
          await _channel.invokeMethod<Map<dynamic, dynamic>>('checkForUpdate');
      if (result == null) {
        return const UpdateInfo(
          status: UpdateStatus.notAvailable,
          updateAvailable: false,
        );
      }

      final bool available = result['updateAvailable'] as bool? ?? false;
      final int priorityRaw = result['priority'] as int? ?? 0;

      return UpdateInfo(
        status: available ? UpdateStatus.available : UpdateStatus.notAvailable,
        updateAvailable: available,
        availableVersion: result['availableVersionCode']?.toString(),
        installedVersion: result['installedVersionCode']?.toString(),
        priority: _mapPriority(priorityRaw),
        immediateAllowed: result['immediateAllowed'] as bool? ?? false,
        flexibleAllowed: result['flexibleAllowed'] as bool? ?? false,
      );
    } on PlatformException catch (e) {
      return UpdateInfo(
        status: UpdateStatus.error,
        updateAvailable: false,
        errorMessage: e.message,
      );
    }
  }

  /// Starts the blocking, full-screen Play Store update flow.
  Future<void> performImmediateUpdate() async {
    await _channel.invokeMethod('performImmediateUpdate');
  }

  /// Starts a background download the user can keep using the app during.
  Future<void> startFlexibleUpdate() async {
    await _channel.invokeMethod('startFlexibleUpdate');
  }

  /// Installs a flexible update that has finished downloading. This
  /// restarts the app.
  Future<void> completeFlexibleUpdate() async {
    await _channel.invokeMethod('completeFlexibleUpdate');
  }

  /// Re-checks whether an immediate update was interrupted (e.g. app was
  /// backgrounded mid-flow) and resumes it if so. Call this from
  /// `didChangeAppLifecycleState` on resume.
  Future<void> resumeStalledUpdateIfNeeded() async {
    await _channel.invokeMethod('resumeStalledUpdateIfNeeded');
  }

  /// Live install-state / download-progress events for a flexible update.
  Stream<UpdateInfo> get downloadProgressStream {
    _progressStream ??= _installStateChannel
        .receiveBroadcastStream()
        .map<UpdateInfo>((event) {
      final map = Map<dynamic, dynamic>.from(event as Map);
      final String statusStr = map['status'] as String? ?? 'downloading';
      final int? bytesDownloaded = map['bytesDownloaded'] as int?;
      final int? totalBytes = map['totalBytesToDownload'] as int?;
      int? progress;
      if (bytesDownloaded != null && totalBytes != null && totalBytes > 0) {
        progress = ((bytesDownloaded / totalBytes) * 100).clamp(0, 100).round();
      }
      return UpdateInfo(
        status: statusStr == 'downloaded'
            ? UpdateStatus.downloaded
            : UpdateStatus.downloading,
        updateAvailable: true,
        downloadProgress: progress,
      );
    });
    return _progressStream!;
  }

  UpdatePriority _mapPriority(int raw) {
    if (raw >= 4) return UpdatePriority.high;
    if (raw >= 2) return UpdatePriority.medium;
    return UpdatePriority.low;
  }
}
