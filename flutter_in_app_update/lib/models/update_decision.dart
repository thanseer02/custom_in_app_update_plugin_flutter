import 'package:flutter_in_app_update/enums/update_policy.dart';

/// Represents the final decision of whether the application should prompt 
/// the user for an update, and with what urgency.
class UpdateDecision {
  /// Whether an update is available compared to the current app version.
  final bool isUpdateAvailable;

  /// Whether the update is mandatory (e.g., minimum version requirement not met).
  final bool isMandatory;

  /// Whether the UI should prompt the user. This is typically true for 
  /// recommended or mandatory updates.
  final bool shouldPromptUser;

  /// The current version of the application installed.
  final String currentVersion;

  /// The available version on the store or backend.
  final String? availableVersion;

  /// The minimum version required by the configuration.
  final String? minimumVersion;

  /// A descriptive reason explaining the decision (useful for logging/debugging).
  final String reason;

  /// The evaluated update policy dictating the urgency of the update.
  final UpdatePolicy policy;

  const UpdateDecision({
    required this.isUpdateAvailable,
    required this.isMandatory,
    required this.shouldPromptUser,
    required this.currentVersion,
    this.availableVersion,
    this.minimumVersion,
    required this.reason,
    required this.policy,
  });

  @override
  String toString() {
    return 'UpdateDecision(isUpdateAvailable: $isUpdateAvailable, isMandatory: $isMandatory, shouldPromptUser: $shouldPromptUser, policy: ${policy.name}, reason: $reason)';
  }
}
