import 'dart:io';
import 'package:flutter/material.dart';
import 'android_update_channel.dart';
import 'ios_update_checker.dart';
import 'default_update_dialog.dart';
import 'update_info.dart';

/// Signature for a fully custom update UI.
///
/// The plugin calls this with the current [UpdateInfo] and two callbacks:
/// - [onUpdate]: call this when the user taps "update" — the plugin then
///   triggers the correct native/App Store flow for you.
/// - [onDismiss]: call this when the user dismisses your UI.
///
/// Return any widget: an [AlertDialog], a bottom sheet's content, a
/// banner, or `null` if you don't want to show anything for this update.
typedef UpdateUiBuilder = Widget? Function(
  BuildContext context,
  UpdateInfo info,
  VoidCallback onUpdate,
  VoidCallback onDismiss,
);

/// Public entry point for the plugin.
///
/// Usage:
/// ```dart
/// await CustomInAppUpdate.checkForUpdate(
///   context: context,
///   iosBundleId: 'com.company.app',
///   iosInstalledVersion: packageInfo.version,
///   uiBuilder: (context, info, onUpdate, onDismiss) {
///     return showModalBottomSheet(
///       context: context,
///       builder: (_) => MyCustomUpdateSheet(info: info, onUpdate: onUpdate),
///     );
///   },
/// );
/// ```
class CustomInAppUpdate {
  CustomInAppUpdate._();

  /// Checks for an update on the current platform and hands the result to
  /// [uiBuilder] so the app can render whatever UI it wants. If
  /// [uiBuilder] is omitted, a simple built-in [AlertDialog] is shown
  /// instead.
  ///
  /// Android: uses Play Core's In-App Update API.
  /// iOS: uses [iosBundleId] + [iosInstalledVersion] to look up the App
  /// Store's current version. Both are required for the iOS path — if
  /// omitted on iOS this simply resolves to "no update available".
  static Future<void> checkForUpdate({
    required BuildContext context,
    UpdateUiBuilder? uiBuilder,
    String? iosBundleId,
    String? iosInstalledVersion,
    String iosCountry = 'us',
  }) async {
    final UpdateInfo info;

    if (Platform.isAndroid) {
      info = await AndroidUpdateChannel.instance.checkForUpdate();
    } else if (Platform.isIOS && iosBundleId != null && iosInstalledVersion != null) {
      info = await IosUpdateChecker.instance.checkForUpdate(
        bundleId: iosBundleId,
        installedVersion: iosInstalledVersion,
        country: iosCountry,
      );
    } else {
      info = const UpdateInfo(
        status: UpdateStatus.notAvailable,
        updateAvailable: false,
      );
    }

    if (!info.updateAvailable) return;
    if (!context.mounted) return;

    void onUpdate() => _startUpdateFlow(info);
    void onDismiss() => Navigator.of(context, rootNavigator: true).maybePop();

    if (uiBuilder != null) {
      uiBuilder(context, info, onUpdate, onDismiss);
    } else {
      showDefaultUpdateDialog(context, info, onUpdate, onDismiss);
    }
  }

  /// Kicks off the correct update flow for the given [info]. Exposed
  /// separately in case a consumer wants to trigger it from somewhere
  /// other than the [UpdateUiBuilder] callback (e.g. a settings screen
  /// "check for update" button with its own state management).
  static Future<void> _startUpdateFlow(UpdateInfo info) async {
    if (!Platform.isAndroid) return; // iOS: consumer's UI should deep-link
    // out to the App Store URL themselves; there's no native flow to start.

    if (info.immediateAllowed) {
      await AndroidUpdateChannel.instance.performImmediateUpdate();
    } else if (info.flexibleAllowed) {
      await AndroidUpdateChannel.instance.startFlexibleUpdate();
    }
  }

  /// Call this once the app is showing a flexible-update "ready to
  /// install" prompt and the user confirms — restarts the app with the
  /// new version installed.
  static Future<void> completeFlexibleUpdate() =>
      AndroidUpdateChannel.instance.completeFlexibleUpdate();

  /// Android only. Live progress for an in-flight flexible update —
  /// feed this into your custom UI's progress bar.
  static Stream<UpdateInfo> get downloadProgressStream =>
      AndroidUpdateChannel.instance.downloadProgressStream;

  /// Call from `didChangeAppLifecycleState` on `AppLifecycleState.resumed`
  /// to resume an immediate update flow that was interrupted (e.g. the
  /// app was killed or backgrounded mid-update).
  static Future<void> resumeStalledUpdateIfNeeded() {
    if (!Platform.isAndroid) return Future.value();
    return AndroidUpdateChannel.instance.resumeStalledUpdateIfNeeded();
  }

  /// TESTING ONLY: Enables local test mode by injecting `FakeAppUpdateManager`.
  /// Must be called before `checkForUpdate()`.
  static Future<void> enableTestMode() {
    if (!Platform.isAndroid) return Future.value();
    return AndroidUpdateChannel.instance.enableTestMode();
  }

  /// TESTING ONLY: Simulates an update being available in test mode.
  /// Must be called after `enableTestMode()`.
  static Future<void> setTestUpdateAvailable({
    bool flexibleAllowed = true,
    bool immediateAllowed = true,
  }) {
    if (!Platform.isAndroid) return Future.value();
    return AndroidUpdateChannel.instance.setTestUpdateAvailable(
      flexibleAllowed: flexibleAllowed,
      immediateAllowed: immediateAllowed,
    );
  }

  /// TESTING ONLY: Simulates download progress in test mode.
  /// Must be called while a flexible update is "downloading".
  static Future<void> simulateDownloadProgress({
    required int bytesDownloaded,
    required int totalBytesToDownload,
  }) {
    if (!Platform.isAndroid) return Future.value();
    return AndroidUpdateChannel.instance.simulateDownloadProgress(
      bytesDownloaded: bytesDownloaded,
      totalBytesToDownload: totalBytesToDownload,
    );
  }
}
