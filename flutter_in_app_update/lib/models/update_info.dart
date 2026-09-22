import '../enums/update_availability.dart';
import '../enums/update_install_status.dart';

/// Contains information about the availability and status of an app update.
class UpdateInfo {
  /// Whether an update is available (helper property based on availability).
  final bool isUpdateAvailable;

  /// The current version of the app.
  final String currentVersion;

  /// The available version of the app on the store.
  final String availableVersion;

  /// The current build number of the app.
  final int currentBuildNumber;

  /// The available build number of the app on the store.
  final int availableBuildNumber;

  /// Whether an immediate update is allowed.
  final bool immediateUpdateAllowed;

  /// Whether a flexible update is allowed.
  final bool flexibleUpdateAllowed;

  /// The priority of the update as defined in Google Play Console (0-5).
  /// Only available on Android. Null on iOS.
  final int? updatePriority;

  /// The number of days since the update was made available on the store.
  /// Only available on Android. Null on iOS.
  final int? clientVersionStalenessDays;

  /// The current installation status of the update (useful for flexible updates).
  final UpdateInstallStatus installStatus;

  /// The availability status of the update.
  final UpdateAvailability availability;

  /// The platform this information was fetched for ('android' or 'ios').
  final String platform;

  const UpdateInfo({
    required this.isUpdateAvailable,
    required this.currentVersion,
    required this.availableVersion,
    required this.currentBuildNumber,
    required this.availableBuildNumber,
    required this.immediateUpdateAllowed,
    required this.flexibleUpdateAllowed,
    this.updatePriority,
    this.clientVersionStalenessDays,
    required this.installStatus,
    required this.availability,
    required this.platform,
  });

  /// Creates an [UpdateInfo] from a JSON map.
  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    return UpdateInfo(
      isUpdateAvailable: json['isUpdateAvailable'] as bool? ?? false,
      currentVersion: json['currentVersion'] as String? ?? '0.0.0',
      availableVersion: json['availableVersion'] as String? ?? '0.0.0',
      currentBuildNumber: json['currentBuildNumber'] as int? ?? 0,
      availableBuildNumber: json['availableBuildNumber'] as int? ?? 0,
      immediateUpdateAllowed: json['immediateUpdateAllowed'] as bool? ?? false,
      flexibleUpdateAllowed: json['flexibleUpdateAllowed'] as bool? ?? false,
      updatePriority: json['updatePriority'] as int?,
      clientVersionStalenessDays: json['clientVersionStalenessDays'] as int?,
      installStatus: _parseInstallStatus(json['installStatus'] as int?),
      availability: _parseAvailability(json['availability'] as int?),
      platform: json['platform'] as String? ?? 'unknown',
    );
  }

  /// Converts the [UpdateInfo] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'isUpdateAvailable': isUpdateAvailable,
      'currentVersion': currentVersion,
      'availableVersion': availableVersion,
      'currentBuildNumber': currentBuildNumber,
      'availableBuildNumber': availableBuildNumber,
      'immediateUpdateAllowed': immediateUpdateAllowed,
      'flexibleUpdateAllowed': flexibleUpdateAllowed,
      'updatePriority': updatePriority,
      'clientVersionStalenessDays': clientVersionStalenessDays,
      'installStatus': installStatus.index,
      'availability': availability.index,
      'platform': platform,
    };
  }

  static UpdateInstallStatus _parseInstallStatus(int? status) {
    if (status == null || status < 0 || status >= UpdateInstallStatus.values.length) {
      return UpdateInstallStatus.unknown;
    }
    return UpdateInstallStatus.values[status];
  }

  static UpdateAvailability _parseAvailability(int? availability) {
    if (availability == null || availability < 0 || availability >= UpdateAvailability.values.length) {
      return UpdateAvailability.unknown;
    }
    return UpdateAvailability.values[availability];
  }
}
