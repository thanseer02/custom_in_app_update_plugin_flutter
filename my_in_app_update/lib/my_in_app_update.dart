
import 'package:flutter/material.dart';

import 'my_in_app_update_platform_interface.dart';
import 'src/enums/update_source.dart';
import 'src/models/download_progress.dart';
import 'src/models/update_info.dart';
import 'src/ui/default_ui_builder.dart';
import 'src/ui/update_ui_builder.dart';

export 'src/enums/update_availability.dart';
export 'src/enums/update_source.dart';
export 'src/enums/update_status.dart';
export 'src/models/download_progress.dart';
export 'src/models/update_info.dart';
export 'src/services/app_store_lookup_service.dart';
export 'src/ui/default_ui_builder.dart';
export 'src/ui/update_ui_builder.dart';
export 'src/widgets/update_prompt_builder.dart';

/// Main entry point for interacting with in-app updates across Android and iOS.
class MyInAppUpdate {
  /// Stream emitting live download progress updates during flexible updates.
  Stream<DownloadProgress> get downloadProgressStream =>
      MyInAppUpdatePlatform.instance.downloadProgressStream;

  /// Returns the native platform version string.
  Future<String?> getPlatformVersion() {
    return MyInAppUpdatePlatform.instance.getPlatformVersion();
  }

  /// Opens the given [url] in the Apple App Store on iOS.
  Future<bool> openAppStore(String url) {
    return MyInAppUpdatePlatform.instance.openAppStore(url);
  }

  /// Checks if an update is available on the platform store (Google Play on Android, iTunes on iOS).
  ///
  /// - [context]: When provided, displays an update prompt if an update is found.
  /// - [uiBuilder]: Custom builder function (defaults to [defaultUiBuilder]).
  /// - [iosBundleId]: Optional bundle identifier override for iOS lookup.
  /// - [iosCountryCode]: Optional two-letter country code (e.g. 'us') for iOS lookup.
  Future<UpdateInfo> checkForUpdate({
    BuildContext? context,
    UpdateUIBuilder? uiBuilder,
    String? iosBundleId,
    String? iosCountryCode,
    bool useRootNavigator = true,
    bool barrierDismissible = true,
    void Function(UpdateInfo info)? onProgress,
    void Function(dynamic error)? onError,
  }) async {
    final info = await MyInAppUpdatePlatform.instance.checkForUpdate(
      iosBundleId: iosBundleId,
      iosCountryCode: iosCountryCode,
    );

    if (context != null && info.isUpdateAvailable && context.mounted) {
      final effectiveBuilder = uiBuilder ?? defaultUiBuilder;
      await showDialog<void>(
        context: context,
        useRootNavigator: useRootNavigator,
        barrierDismissible: barrierDismissible,
        builder: (dialogContext) {
          return effectiveBuilder(
            dialogContext,
            info,
            () async {
              if (barrierDismissible && dialogContext.mounted) {
                Navigator.of(dialogContext, rootNavigator: useRootNavigator).pop();
              }
              try {
                await _performPlatformUpdate(info, onProgress: onProgress);
              } catch (e) {
                onError?.call(e);
              }
            },
            () {
              if (dialogContext.mounted) {
                Navigator.of(dialogContext, rootNavigator: useRootNavigator).pop();
              }
            },
          );
        },
      );
    }

    return info;
  }

  /// Displays the update prompt for a previously fetched [UpdateInfo].
  ///
  /// Defaults to [defaultUiBuilder] if [uiBuilder] is not provided.
  Future<void> promptUpdate({
    required BuildContext context,
    required UpdateInfo info,
    UpdateUIBuilder? uiBuilder,
    bool useRootNavigator = true,
    bool barrierDismissible = true,
    void Function(UpdateInfo info)? onProgress,
    void Function(dynamic error)? onError,
  }) async {
    if (!context.mounted) return;

    final effectiveBuilder = uiBuilder ?? defaultUiBuilder;

    await showDialog<void>(
      context: context,
      useRootNavigator: useRootNavigator,
      barrierDismissible: barrierDismissible,
      builder: (dialogContext) {
        return effectiveBuilder(
          dialogContext,
          info,
          () async {
            if (barrierDismissible && dialogContext.mounted) {
              Navigator.of(dialogContext, rootNavigator: useRootNavigator).pop();
            }
            try {
              await _performPlatformUpdate(info, onProgress: onProgress);
            } catch (e) {
              onError?.call(e);
            }
          },
          () {
            if (dialogContext.mounted) {
              Navigator.of(dialogContext, rootNavigator: useRootNavigator).pop();
            }
          },
        );
      },
    );
  }

  /// Internal handler that executes the appropriate platform update mechanism.
  Future<void> _performPlatformUpdate(
    UpdateInfo info, {
    void Function(UpdateInfo info)? onProgress,
  }) async {
    if (info.source == UpdateSource.appStore && info.appStoreUrl != null && info.appStoreUrl!.isNotEmpty) {
      await openAppStore(info.appStoreUrl!);
    } else if (info.immediateAllowed) {
      await startImmediateUpdate();
    } else if (info.flexibleAllowed) {
      await startFlexibleUpdate(onProgress: onProgress);
    } else if (info.appStoreUrl != null && info.appStoreUrl!.isNotEmpty) {
      await openAppStore(info.appStoreUrl!);
    }
  }

  /// Starts an immediate (full-screen blocking) update flow on Android.
  Future<void> startImmediateUpdate() {
    return MyInAppUpdatePlatform.instance.startImmediateUpdate();
  }

  /// Starts an immediate update flow (alias for [startImmediateUpdate]).
  Future<void> performImmediateUpdate() {
    return MyInAppUpdatePlatform.instance.performImmediateUpdate();
  }

  /// Starts a flexible (background download) update flow on Android.
  ///
  /// Optional [onProgress] callback reports progress updates as bytes download.
  Future<void> startFlexibleUpdate({
    void Function(UpdateInfo updateInfo)? onProgress,
  }) {
    return MyInAppUpdatePlatform.instance.startFlexibleUpdate(
      onProgress: onProgress,
    );
  }

  /// Completes a flexible update by installing the downloaded update and restarting the app.
  Future<void> completeFlexibleUpdate() {
    return MyInAppUpdatePlatform.instance.completeFlexibleUpdate();
  }
}
