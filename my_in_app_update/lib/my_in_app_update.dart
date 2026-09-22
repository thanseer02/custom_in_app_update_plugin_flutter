
import 'package:flutter/material.dart';

import 'my_in_app_update_platform_interface.dart';
import 'src/models/download_progress.dart';
import 'src/models/update_info.dart';
import 'src/ui/update_ui_builder.dart';

export 'src/enums/update_availability.dart';
export 'src/enums/update_status.dart';
export 'src/models/download_progress.dart';
export 'src/models/update_info.dart';
export 'src/ui/update_ui_builder.dart';
export 'src/widgets/update_prompt_builder.dart';

/// Main entry point for interacting with in-app updates.
class MyInAppUpdate {
  /// Stream emitting live download progress updates during flexible updates.
  Stream<DownloadProgress> get downloadProgressStream =>
      MyInAppUpdatePlatform.instance.downloadProgressStream;

  /// Returns the native platform version string.
  Future<String?> getPlatformVersion() {
    return MyInAppUpdatePlatform.instance.getPlatformVersion();
  }

  /// Checks if an update is available on the platform store.
  ///
  /// If [uiBuilder] and [context] are provided, and an update is available,
  /// the plugin invokes [uiBuilder] to present a completely custom UI
  /// (e.g. [AlertDialog], [BottomSheet], or custom overlay) passing the
  /// [UpdateInfo], [onUpdate] callback, and [onDismiss] callback.
  Future<UpdateInfo> checkForUpdate({
    BuildContext? context,
    UpdateUIBuilder? uiBuilder,
    bool useRootNavigator = true,
    bool barrierDismissible = true,
    void Function(UpdateInfo info)? onProgress,
    void Function(dynamic error)? onError,
  }) async {
    final info = await MyInAppUpdatePlatform.instance.checkForUpdate();

    if (context != null && uiBuilder != null && info.isUpdateAvailable && context.mounted) {
      await showDialog<void>(
        context: context,
        useRootNavigator: useRootNavigator,
        barrierDismissible: barrierDismissible,
        builder: (dialogContext) {
          return uiBuilder(
            dialogContext,
            info,
            () async {
              if (barrierDismissible && dialogContext.mounted) {
                Navigator.of(dialogContext, rootNavigator: useRootNavigator).pop();
              }
              try {
                if (info.immediateAllowed) {
                  await startImmediateUpdate();
                } else if (info.flexibleAllowed) {
                  await startFlexibleUpdate(onProgress: onProgress);
                }
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

  /// Displays the custom [uiBuilder] dialog/prompt for a previously fetched [UpdateInfo].
  Future<void> promptUpdate({
    required BuildContext context,
    required UpdateInfo info,
    required UpdateUIBuilder uiBuilder,
    bool useRootNavigator = true,
    bool barrierDismissible = true,
    void Function(UpdateInfo info)? onProgress,
    void Function(dynamic error)? onError,
  }) async {
    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      useRootNavigator: useRootNavigator,
      barrierDismissible: barrierDismissible,
      builder: (dialogContext) {
        return uiBuilder(
          dialogContext,
          info,
          () async {
            if (barrierDismissible && dialogContext.mounted) {
              Navigator.of(dialogContext, rootNavigator: useRootNavigator).pop();
            }
            try {
              if (info.immediateAllowed) {
                await startImmediateUpdate();
              } else if (info.flexibleAllowed) {
                await startFlexibleUpdate(onProgress: onProgress);
              }
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

  /// Starts an immediate (full-screen blocking) update flow.
  Future<void> startImmediateUpdate() {
    return MyInAppUpdatePlatform.instance.startImmediateUpdate();
  }

  /// Alias for [startImmediateUpdate].
  Future<void> performImmediateUpdate() {
    return MyInAppUpdatePlatform.instance.performImmediateUpdate();
  }

  /// Starts a flexible (background download) update flow.
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
