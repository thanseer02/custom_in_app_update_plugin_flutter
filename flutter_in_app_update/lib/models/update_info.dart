import '../enums/update_availability.dart';
import '../enums/update_install_status.dart';
import '../enums/update_type.dart';

/// Contains comprehensive information about an available update, if any,
/// and the current installation status.
class UpdateInfo {
  /// Whether an update is available to be installed.
  final bool isUpdateAvailable;

  /// The current availability state of the update.
  final UpdateAvailability updateAvailability;

  /// The current version of the app installed on the device.
  final String currentVersion;

  /// The version of the available update, if any.
  final String? availableVersion;

  /// The current build number of the app installed on the device.
  final int? currentBuildNumber;

  /// The build number of the available update, if any.
  final int? availableBuildNumber;

  /// A list of update types that are allowed for the current update.
  final List<UpdateType> allowedUpdateTypes;

  /// The priority of the update, typically provided by the store (e.g., 0 to 5 on Android).
  final int updatePriority;

  /// The number of days since the update was made available on the store.
  final int? clientVersionStalenessDays;

  /// The current installation status of the update (e.g., downloading, installed).
  final UpdateInstallStatus installStatus;

  /// The platform for which this update info was retrieved ('android' or 'ios').
  final String platform;

  /// Creates a new [UpdateInfo] instance.
  const UpdateInfo({
    required this.isUpdateAvailable,
    required this.updateAvailability,
    required this.currentVersion,
    this.availableVersion,
    this.currentBuildNumber,
    this.availableBuildNumber,
    this.allowedUpdateTypes = const [],
    this.updatePriority = 0,
    this.clientVersionStalenessDays,
    this.installStatus = UpdateInstallStatus.unknown,
    required this.platform,
  });

  /// Creates an [UpdateInfo] from a Map (typically received from native side).
  factory UpdateInfo.fromMap(Map<String, dynamic> map) {
    return UpdateInfo(
      isUpdateAvailable: map['isUpdateAvailable'] as bool? ?? false,
      updateAvailability: UpdateAvailability.values.firstWhere(
        (e) => e.name == map['updateAvailability'],
        orElse: () => UpdateAvailability.unknown,
      ),
      currentVersion: map['currentVersion'] as String? ?? '0.0.0',
      availableVersion: map['availableVersion'] as String?,
      currentBuildNumber: map['currentBuildNumber'] as int?,
      availableBuildNumber: map['availableBuildNumber'] as int?,
      allowedUpdateTypes: (map['allowedUpdateTypes'] as List<dynamic>?)
              ?.map((e) => UpdateType.values.firstWhere(
                    (type) => type.name == e,
                    orElse: () => UpdateType.flexible,
                  ))
              .toList() ??
          [],
      updatePriority: map['updatePriority'] as int? ?? 0,
      clientVersionStalenessDays: map['clientVersionStalenessDays'] as int?,
      installStatus: UpdateInstallStatus.values.firstWhere(
        (e) => e.name == map['installStatus'],
        orElse: () => UpdateInstallStatus.unknown,
      ),
      platform: map['platform'] as String? ?? 'unknown',
    );
  }

  /// Converts the [UpdateInfo] instance to a Map.
  Map<String, dynamic> toMap() {
    return {
      'isUpdateAvailable': isUpdateAvailable,
      'updateAvailability': updateAvailability.name,
      'currentVersion': currentVersion,
      'availableVersion': availableVersion,
      'currentBuildNumber': currentBuildNumber,
      'availableBuildNumber': availableBuildNumber,
      'allowedUpdateTypes': allowedUpdateTypes.map((e) => e.name).toList(),
      'updatePriority': updatePriority,
      'clientVersionStalenessDays': clientVersionStalenessDays,
      'installStatus': installStatus.name,
      'platform': platform,
    };
  }
}
