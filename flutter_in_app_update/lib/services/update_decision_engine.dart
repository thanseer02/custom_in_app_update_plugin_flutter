import 'package:flutter_in_app_update/enums/update_policy.dart';
import 'package:flutter_in_app_update/models/in_app_update_config.dart';
import 'package:flutter_in_app_update/models/update_decision.dart';
import 'package:flutter_in_app_update/services/version_comparator.dart';

/// The engine responsible for evaluating update rules and generating an [UpdateDecision].
class UpdateDecisionEngine {
  /// Evaluates the current state against the provided configuration.
  /// 
  /// [currentVersion] The app's current installed version.
  /// [storeVersion] The version available on the store (if any).
  /// [config] The update constraints.
  static UpdateDecision evaluate({
    required String currentVersion,
    String? storeVersion,
    required InAppUpdateConfig config,
  }) {
    // 1. Determine available/latest version. Config overrides store.
    String? targetVersion = config.latestVersion ?? storeVersion;

    // 2. If no target version is known, no update is possible.
    if (targetVersion == null || targetVersion.isEmpty) {
      return UpdateDecision(
        isUpdateAvailable: false,
        isMandatory: false,
        shouldPromptUser: false,
        currentVersion: currentVersion,
        availableVersion: targetVersion,
        minimumVersion: config.minimumVersion,
        reason: 'No available version known.',
        policy: UpdatePolicy.none,
      );
    }

    // 3. Determine if any update is available at all.
    bool updateAvailable = VersionComparator.isUpdateAvailable(
      currentVersion, 
      targetVersion,
    );

    if (!updateAvailable) {
      return UpdateDecision(
        isUpdateAvailable: false,
        isMandatory: false,
        shouldPromptUser: false,
        currentVersion: currentVersion,
        availableVersion: targetVersion,
        minimumVersion: config.minimumVersion,
        reason: 'App is up to date.',
        policy: UpdatePolicy.none,
      );
    }

    // 4. Check Mandatory constraints.
    // If the current version is LESS than the minimum version, it is mandatory.
    bool failsMinimum = false;
    if (config.minimumVersion != null && config.minimumVersion!.isNotEmpty) {
      failsMinimum = VersionComparator.compare(currentVersion, config.minimumVersion) < 0;
    }

    if (failsMinimum || config.forceUpdate) {
      return UpdateDecision(
        isUpdateAvailable: true,
        isMandatory: true,
        shouldPromptUser: true,
        currentVersion: currentVersion,
        availableVersion: targetVersion,
        minimumVersion: config.minimumVersion,
        reason: failsMinimum 
          ? 'Current version is below minimum required version.'
          : 'Force update is enabled in configuration.',
        policy: UpdatePolicy.mandatory,
      );
    }

    // 5. Check Recommended constraints.
    if (config.recommendedVersion != null && config.recommendedVersion!.isNotEmpty) {
      bool belowRecommended = VersionComparator.compare(currentVersion, config.recommendedVersion) < 0;
      if (belowRecommended) {
        return UpdateDecision(
          isUpdateAvailable: true,
          isMandatory: false,
          shouldPromptUser: true,
          currentVersion: currentVersion,
          availableVersion: targetVersion,
          minimumVersion: config.minimumVersion,
          reason: 'Current version is below recommended version.',
          policy: UpdatePolicy.recommended,
        );
      }
    }

    // 6. Otherwise, it's just an optional update.
    return UpdateDecision(
      isUpdateAvailable: true,
      isMandatory: false,
      shouldPromptUser: false, // Optional updates might not actively prompt users depending on app logic
      currentVersion: currentVersion,
      availableVersion: targetVersion,
      minimumVersion: config.minimumVersion,
      reason: 'A newer version is available but not strictly recommended or required.',
      policy: UpdatePolicy.optional,
    );
  }
}
