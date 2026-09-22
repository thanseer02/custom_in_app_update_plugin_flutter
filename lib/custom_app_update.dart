library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'src/models.dart';
export 'src/models.dart';

enum UpdatePhase {
  idle,
  unsupported,
  upToDate,
  unavailable,
  available,
  awaitingConsent,
  pending,
  downloading,
  readyToInstall,
  installing,
  installed,
  canceled,
  failed,
}

/// Implement this interface to test your UI without a Play Store release.
abstract interface class UpdateBackend {
  bool get isSupported;
  Stream<UpdateInstallState> get statuses;
  Future<AppUpdateInfo> check();
  Future<AppUpdateResult> download();
  Future<void> install();
}

class GooglePlayUpdateBackend implements UpdateBackend {
  static const _methods = MethodChannel('dev.customappupdate/methods');
  static const _events = EventChannel('dev.customappupdate/events');

  @override
  bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  Stream<UpdateInstallState> get statuses =>
      _events.receiveBroadcastStream().map((event) =>
          UpdateInstallState.fromMap(Map<Object?, Object?>.from(event as Map)));

  @override
  Future<AppUpdateInfo> check() async {
    final result = await _methods.invokeMapMethod<Object?, Object?>('check');
    if (result == null) {
      throw PlatformException(code: 'EMPTY_RESPONSE');
    }
    return AppUpdateInfo.fromMap(result);
  }

  @override
  Future<AppUpdateResult> download() async {
    return switch (await _methods.invokeMethod<String>('download')) {
      'downloaded' => AppUpdateResult.success,
      'canceled' => AppUpdateResult.userDeniedUpdate,
      _ => AppUpdateResult.inAppUpdateFailed,
    };
  }

  @override
  Future<void> install() => _methods.invokeMethod<void>('install');
}

/// Own ONE controller above your routes/dialogs/sheets and dispose it with
/// that owner. Closing an update surface must not dispose this controller.
///
/// This controller never opens UI, automatically prompts, or installs without
/// an explicit [restartAndInstall] call. Google Play owns the consent screen.
class CustomAppUpdateController extends ChangeNotifier
    with WidgetsBindingObserver {
  CustomAppUpdateController({UpdateBackend? backend})
      : _backend = backend ?? GooglePlayUpdateBackend() {
    WidgetsBinding.instance.addObserver(this);
  }

  final UpdateBackend _backend;
  StreamSubscription<UpdateInstallState>? _subscription;
  UpdatePhase _phase = UpdatePhase.idle;
  AppUpdateInfo? _info;
  Object? _error;
  bool _disposed = false;
  bool _checking = false;
  bool _starting = false;
  bool _completing = false;
  int _statusRevision = 0;
  Future<void>? _checkFuture;
  int _bytesDownloaded = 0;
  int _totalBytesToDownload = 0;

  UpdatePhase get phase => _phase;
  AppUpdateInfo? get info => _info;
  Object? get error => _error;
  bool get isChecking => _checking;

  int get bytesDownloaded => _bytesDownloaded;
  int get totalBytesToDownload => _totalBytesToDownload;

  /// Real progress in [0, 1]; null until Play reports a download size.
  double? get downloadProgress {
    if (_phase == UpdatePhase.readyToInstall) return 1;
    if (_phase != UpdatePhase.downloading || _totalBytesToDownload <= 0) {
      return null;
    }
    return (_bytesDownloaded / _totalBytesToDownload).clamp(0.0, 1.0);
  }

  bool get canDownload =>
      !_disposed &&
      !_checking &&
      !_starting &&
      !_completing &&
      _info?.flexibleUpdateAllowed == true &&
      _info?.updateAvailability == UpdateAvailability.updateAvailable &&
      const {
        UpdatePhase.available,
        UpdatePhase.canceled,
        UpdatePhase.failed,
      }.contains(_phase);

  bool get canInstall =>
      !_disposed && !_completing && _phase == UpdatePhase.readyToInstall;

  /// Checks without showing any UI. Concurrent checks share one request.
  Future<void> check() {
    if (_disposed) return Future<void>.value();
    return _checkFuture ??= _refresh().whenComplete(() => _checkFuture = null);
  }

  Future<void> _refresh() async {
    if (!_backend.isSupported) {
      _setPhase(UpdatePhase.unsupported);
      return;
    }
    _checking = true;
    _error = null;
    _notify();
    final revision = _statusRevision;
    try {
      _subscription ??= _backend.statuses.listen(
        _onStatus,
        onError: (Object error, StackTrace stack) {
          if (_disposed) return;
          _error = error;
          _notify();
        },
      );
      final info = await _backend.check();
      if (_disposed) return;
      _info = info;
      // A live status received during this request is more recent than its
      // snapshot. Do not replace a downloaded event with an older state.
      if (revision != _statusRevision) return;
      _bytesDownloaded = info.bytesDownloaded;
      _totalBytesToDownload = info.totalBytesToDownload;
      if (_applyInstallStatus(info.installStatus)) return;
      if (_phase == UpdatePhase.awaitingConsent || _completing) return;
      _phase = switch (info.updateAvailability) {
        UpdateAvailability.updateAvailable => info.flexibleUpdateAllowed
            ? UpdatePhase.available
            : UpdatePhase.unavailable,
        UpdateAvailability.updateNotAvailable => UpdatePhase.upToDate,
        _ => UpdatePhase.unavailable,
      };
    } catch (error) {
      if (_disposed) return;
      _error = error;
      // A temporary check failure must not lose an already downloaded update.
      if (!const {
        UpdatePhase.readyToInstall,
        UpdatePhase.downloading,
        UpdatePhase.pending,
        UpdatePhase.awaitingConsent,
        UpdatePhase.installing,
      }.contains(_phase)) {
        _phase = UpdatePhase.failed;
      }
    } finally {
      _checking = false;
      _notify();
    }
  }

  /// Call from your custom Update button. The Play consent UI appears next.
  /// The future can remain pending throughout the download; render [phase]
  /// reactively instead of waiting for this future to rebuild the UI.
  Future<void> download() async {
    if (!canDownload) return;
    _starting = true;
    try {
      // Google requires fresh update information for each new attempt.
      await check();
      if (_disposed ||
          _phase != UpdatePhase.available &&
              _phase != UpdatePhase.canceled &&
              _phase != UpdatePhase.failed) {
        return;
      }
      if (_error != null ||
          _info?.flexibleUpdateAllowed != true ||
          _info?.updateAvailability != UpdateAvailability.updateAvailable) {
        return;
      }
      _error = null;
      _bytesDownloaded = 0;
      _totalBytesToDownload = 0;
      _setPhase(UpdatePhase.awaitingConsent);
      final result = await _backend.download();
      if (_disposed) return;
      switch (result) {
        case AppUpdateResult.success:
          if (_phase != UpdatePhase.installing &&
              _phase != UpdatePhase.installed) {
            _setPhase(UpdatePhase.readyToInstall);
          }
        case AppUpdateResult.userDeniedUpdate:
          _setPhase(UpdatePhase.canceled);
        case AppUpdateResult.inAppUpdateFailed:
          _error = StateError('Google Play could not complete the update.');
          _setPhase(UpdatePhase.failed);
      }
    } catch (error) {
      if (_disposed) return;
      _error = error;
      _setPhase(UpdatePhase.failed);
    } finally {
      _starting = false;
      _notify();
    }
  }

  /// Call only after your user chooses Restart. Save their work first.
  /// The app can restart before this future returns.
  Future<void> restartAndInstall() async {
    if (!canInstall) return;
    _completing = true;
    _error = null;
    _setPhase(UpdatePhase.installing);
    try {
      await _backend.install();
      // Keep installing until Play reports completion or the app restarts.
    } catch (error) {
      if (_disposed) return;
      _error = error;
      _setPhase(UpdatePhase.readyToInstall);
    } finally {
      _completing = false;
      _notify();
    }
  }

  void _onStatus(UpdateInstallState state) {
    if (_disposed || state.status == InstallStatus.unknown) return;
    _statusRevision++;
    _bytesDownloaded = state.bytesDownloaded;
    _totalBytesToDownload = state.totalBytesToDownload;
    if (state.errorCode != 0) {
      _error = PlatformException(
        code: 'PLAY_INSTALL_ERROR',
        message: 'Google Play install error ${state.errorCode}',
        details: state.errorCode,
      );
    }
    if (_applyInstallStatus(state.status)) _notify();
  }

  bool _applyInstallStatus(InstallStatus status) {
    final next = switch (status) {
      InstallStatus.pending => UpdatePhase.pending,
      InstallStatus.downloading => UpdatePhase.downloading,
      InstallStatus.downloaded => UpdatePhase.readyToInstall,
      InstallStatus.installing => UpdatePhase.installing,
      InstallStatus.installed => UpdatePhase.installed,
      InstallStatus.canceled => UpdatePhase.canceled,
      InstallStatus.failed => UpdatePhase.failed,
      InstallStatus.unknown => null,
    };
    if (next == null) return false;
    _phase = next;
    return true;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(check());
  }

  void _setPhase(UpdatePhase value) {
    if (_disposed) return;
    _phase = value;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
