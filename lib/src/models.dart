/// Values correspond to the official Google Play update API constants.
enum UpdateAvailability {
  unknown(0),
  updateNotAvailable(1),
  updateAvailable(2),
  developerTriggeredUpdateInProgress(3);

  const UpdateAvailability(this.value);
  final int value;

  static UpdateAvailability fromValue(int? value) => values.firstWhere(
        (item) => item.value == value,
        orElse: () => unknown,
      );
}

enum InstallStatus {
  unknown(0),
  pending(1),
  downloading(2),
  installing(3),
  installed(4),
  failed(5),
  canceled(6),
  downloaded(11);

  const InstallStatus(this.value);
  final int value;

  static InstallStatus fromValue(int? value) => values.firstWhere(
        (item) => item.value == value,
        orElse: () => unknown,
      );
}

enum AppUpdateResult { success, userDeniedUpdate, inAppUpdateFailed }

/// Native status and byte counts, delivered together to avoid mismatched UI.
class UpdateInstallState {
  const UpdateInstallState({
    required this.status,
    this.bytesDownloaded = 0,
    this.totalBytesToDownload = 0,
    this.errorCode = 0,
  });

  factory UpdateInstallState.fromMap(Map<Object?, Object?> map) =>
      UpdateInstallState(
        status: InstallStatus.fromValue(map['installStatus'] as int?),
        bytesDownloaded: (map['bytesDownloaded'] as num?)?.toInt() ?? 0,
        totalBytesToDownload:
            (map['totalBytesToDownload'] as num?)?.toInt() ?? 0,
        errorCode: (map['errorCode'] as num?)?.toInt() ?? 0,
      );

  final InstallStatus status;
  final int bytesDownloaded;
  final int totalBytesToDownload;
  final int errorCode;
}

class AppUpdateInfo {
  const AppUpdateInfo({
    required this.updateAvailability,
    required this.flexibleUpdateAllowed,
    required this.installStatus,
    required this.packageName,
    this.immediateUpdateAllowed = false,
    this.immediateAllowedPreconditions,
    this.flexibleAllowedPreconditions,
    this.availableVersionCode,
    this.clientVersionStalenessDays,
    this.updatePriority = 0,
    this.bytesDownloaded = 0,
    this.totalBytesToDownload = 0,
  });

  factory AppUpdateInfo.fromMap(Map<Object?, Object?> map) => AppUpdateInfo(
        updateAvailability:
            UpdateAvailability.fromValue(map['updateAvailability'] as int?),
        flexibleUpdateAllowed: map['flexibleUpdateAllowed'] == true,
        immediateUpdateAllowed: map['immediateUpdateAllowed'] == true,
        installStatus: InstallStatus.fromValue(map['installStatus'] as int?),
        packageName: map['packageName'] as String? ?? '',
        availableVersionCode: map['availableVersionCode'] as int?,
        clientVersionStalenessDays: map['clientVersionStalenessDays'] as int?,
        updatePriority: map['updatePriority'] as int? ?? 0,
        flexibleAllowedPreconditions:
            (map['flexibleAllowedPreconditions'] as List?)?.cast<int>(),
        immediateAllowedPreconditions:
            (map['immediateAllowedPreconditions'] as List?)?.cast<int>(),
        bytesDownloaded: (map['bytesDownloaded'] as num?)?.toInt() ?? 0,
        totalBytesToDownload:
            (map['totalBytesToDownload'] as num?)?.toInt() ?? 0,
      );

  final UpdateAvailability updateAvailability;
  final bool flexibleUpdateAllowed;
  final bool immediateUpdateAllowed;
  final InstallStatus installStatus;
  final String packageName;
  final int? availableVersionCode;
  final int? clientVersionStalenessDays;
  final int updatePriority;
  final List<int>? flexibleAllowedPreconditions;
  final List<int>? immediateAllowedPreconditions;
  final int bytesDownloaded;
  final int totalBytesToDownload;
}
