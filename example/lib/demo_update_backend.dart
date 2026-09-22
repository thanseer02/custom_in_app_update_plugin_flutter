import 'dart:async';

import 'package:custom_app_update/custom_app_update.dart';

enum DemoScenario { success, canceled, downloadFailure, installFailure }

/// Example-only simulation. Does not download or install an actual app.
class DemoUpdateBackend implements UpdateBackend {
  final _events = StreamController<UpdateInstallState>.broadcast(sync: true);
  DemoScenario scenario = DemoScenario.success;
  InstallStatus _status = InstallStatus.unknown;
  int _bytes = 0;
  bool _disposed = false;
  static const _totalBytes = 20 * 1024 * 1024;

  @override
  bool get isSupported => true;

  @override
  Stream<UpdateInstallState> get statuses => _events.stream;

  @override
  Future<AppUpdateInfo> check() async => AppUpdateInfo(
        updateAvailability: _status == InstallStatus.installed
            ? UpdateAvailability.updateNotAvailable
            : UpdateAvailability.updateAvailable,
        flexibleUpdateAllowed: _status != InstallStatus.installed,
        installStatus: _status,
        packageName: 'dev.customappupdate.example',
        availableVersionCode: 11,
        bytesDownloaded: _bytes,
        totalBytesToDownload:
            _status == InstallStatus.unknown ? 0 : _totalBytes,
      );

  void _emit(InstallStatus status, {int errorCode = 0}) {
    if (_disposed) return;
    _status = status;
    _events.add(UpdateInstallState(
      status: status,
      bytesDownloaded: _bytes,
      totalBytesToDownload: _totalBytes,
      errorCode: errorCode,
    ));
  }

  @override
  Future<AppUpdateResult> download() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (_disposed) return AppUpdateResult.userDeniedUpdate;
    if (scenario == DemoScenario.canceled) {
      _emit(InstallStatus.canceled);
      return AppUpdateResult.userDeniedUpdate;
    }
    _bytes = 0;
    _emit(InstallStatus.pending);
    for (var step = 1; step <= 20; step++) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      if (_disposed) return AppUpdateResult.userDeniedUpdate;
      _bytes = (_totalBytes * step / 20).round();
      if (scenario == DemoScenario.downloadFailure && step == 8) {
        _emit(InstallStatus.failed, errorCode: -2);
        return AppUpdateResult.inAppUpdateFailed;
      }
      _emit(InstallStatus.downloading);
    }
    _emit(InstallStatus.downloaded);
    return AppUpdateResult.success;
  }

  @override
  Future<void> install() async {
    if (scenario == DemoScenario.installFailure) {
      throw StateError('Simulated installation failure.');
    }
    _emit(InstallStatus.installing);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    _emit(InstallStatus.installed);
  }

  void reset() {
    _status = InstallStatus.unknown;
    _bytes = 0;
  }

  void dispose() {
    _disposed = true;
    unawaited(_events.close());
  }
}
