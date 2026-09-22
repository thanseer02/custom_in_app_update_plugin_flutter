import 'package:flutter/foundation.dart';
import '../enums/update_availability.dart';
import '../enums/update_source.dart';

/// Platform-agnostic update information returned by the plugin.
/// Consumers can build custom UI/logic off this model without coupling to native platform types.
@immutable
class UpdateInfo {
  /// The version code / track ID of the available update (0 if none available).
  final int versionCode;

  /// The human-readable version name of the available update (e.g. "2.1.0").
  final String? availableVersion;

  /// The currently installed version name (e.g. "2.0.0").
  final String? currentVersion;

  /// Release notes / changelog for the available version (available on iOS / custom remote).
  final String? releaseNotes;

  /// Direct URL to the application page on the platform store.
  final String? appStoreUrl;

  /// The source platform/API from which update metadata was resolved.
  final UpdateSource source;

  /// The update availability status.
  final UpdateAvailability availability;

  /// The developer-defined priority of the update (0 to 5 on Google Play).
  final int priority;

  /// Whether an immediate/blocking update flow is allowed.
  final bool immediateAllowed;

  /// Whether a flexible/background download update flow is allowed.
  final bool flexibleAllowed;

  /// Number of days since the Google Play Store learned that an update is available.
  final int? clientVersionStalenessDays;

  /// Internal install status code (0: UNKNOWN, 1: PENDING, 2: DOWNLOADING, 3: DOWNLOADED, 4: INSTALLING, 5: INSTALLED, 6: FAILED, 7: CANCELED).
  final int installStatus;

  /// Total bytes downloaded so far during flexible update.
  final int bytesDownloaded;

  /// Total bytes to download for the update.
  final int totalBytesToDownload;

  const UpdateInfo({
    required this.versionCode,
    required this.availability,
    this.availableVersion,
    this.currentVersion,
    this.releaseNotes,
    this.appStoreUrl,
    this.source = UpdateSource.playStore,
    this.priority = 0,
    this.immediateAllowed = false,
    this.flexibleAllowed = false,
    this.clientVersionStalenessDays,
    this.installStatus = 0,
    this.bytesDownloaded = 0,
    this.totalBytesToDownload = 0,
  });

  /// Convenience getter indicating if an update is available.
  bool get isUpdateAvailable => availability == UpdateAvailability.available;

  /// Convenience getter for download progress percentage (0.0 to 1.0).
  double get downloadProgress {
    if (totalBytesToDownload <= 0) return 0.0;
    return (bytesDownloaded / totalBytesToDownload).clamp(0.0, 1.0);
  }

  /// Creates an [UpdateInfo] instance from a Map returned by native platform channels.
  factory UpdateInfo.fromMap(Map<dynamic, dynamic> map) {
    UpdateSource resolvedSource = UpdateSource.playStore;
    if (map['source'] != null) {
      final srcStr = map['source'].toString();
      if (srcStr.contains('appStore')) {
        resolvedSource = UpdateSource.appStore;
      } else if (srcStr.contains('customRemote')) {
        resolvedSource = UpdateSource.customRemote;
      }
    }

    return UpdateInfo(
      versionCode: (map['availableVersionCode'] as num?)?.toInt() ??
          (map['versionCode'] as num?)?.toInt() ??
          0,
      availableVersion: map['availableVersion'] as String? ?? map['versionName'] as String?,
      currentVersion: map['currentVersion'] as String?,
      releaseNotes: map['releaseNotes'] as String?,
      appStoreUrl: map['appStoreUrl'] as String? ?? map['trackViewUrl'] as String?,
      source: resolvedSource,
      availability: map['updateAvailability'] is UpdateAvailability
          ? map['updateAvailability'] as UpdateAvailability
          : UpdateAvailability.fromValue(
              (map['updateAvailability'] as num?)?.toInt() ??
                  (map['availability'] as num?)?.toInt(),
            ),
      priority: (map['updatePriority'] as num?)?.toInt() ??
          (map['priority'] as num?)?.toInt() ??
          0,
      immediateAllowed: (map['immediateAllowed'] as bool?) ?? false,
      flexibleAllowed: (map['flexibleAllowed'] as bool?) ?? false,
      clientVersionStalenessDays:
          (map['clientVersionStalenessDays'] as num?)?.toInt(),
      installStatus: (map['installStatus'] as num?)?.toInt() ?? 0,
      bytesDownloaded: (map['bytesDownloaded'] as num?)?.toInt() ?? 0,
      totalBytesToDownload: (map['totalBytesToDownload'] as num?)?.toInt() ?? 0,
    );
  }

  /// Converts this [UpdateInfo] into a Map.
  Map<String, dynamic> toMap() {
    return {
      'versionCode': versionCode,
      'availableVersionCode': versionCode,
      'availableVersion': availableVersion,
      'currentVersion': currentVersion,
      'releaseNotes': releaseNotes,
      'appStoreUrl': appStoreUrl,
      'source': source.name,
      'availability': availability.value,
      'updateAvailability': availability.value,
      'priority': priority,
      'updatePriority': priority,
      'immediateAllowed': immediateAllowed,
      'flexibleAllowed': flexibleAllowed,
      'clientVersionStalenessDays': clientVersionStalenessDays,
      'installStatus': installStatus,
      'bytesDownloaded': bytesDownloaded,
      'totalBytesToDownload': totalBytesToDownload,
    };
  }

  /// Creates a copy with modified fields.
  UpdateInfo copyWith({
    int? versionCode,
    String? availableVersion,
    String? currentVersion,
    String? releaseNotes,
    String? appStoreUrl,
    UpdateSource? source,
    UpdateAvailability? availability,
    int? priority,
    bool? immediateAllowed,
    bool? flexibleAllowed,
    int? clientVersionStalenessDays,
    int? installStatus,
    int? bytesDownloaded,
    int? totalBytesToDownload,
  }) {
    return UpdateInfo(
      versionCode: versionCode ?? this.versionCode,
      availableVersion: availableVersion ?? this.availableVersion,
      currentVersion: currentVersion ?? this.currentVersion,
      releaseNotes: releaseNotes ?? this.releaseNotes,
      appStoreUrl: appStoreUrl ?? this.appStoreUrl,
      source: source ?? this.source,
      availability: availability ?? this.availability,
      priority: priority ?? this.priority,
      immediateAllowed: immediateAllowed ?? this.immediateAllowed,
      flexibleAllowed: flexibleAllowed ?? this.flexibleAllowed,
      clientVersionStalenessDays:
          clientVersionStalenessDays ?? this.clientVersionStalenessDays,
      installStatus: installStatus ?? this.installStatus,
      bytesDownloaded: bytesDownloaded ?? this.bytesDownloaded,
      totalBytesToDownload: totalBytesToDownload ?? this.totalBytesToDownload,
    );
  }

  @override
  String toString() {
    return 'UpdateInfo(versionCode: $versionCode, version: $availableVersion, availability: $availability, source: $source, priority: $priority, immediateAllowed: $immediateAllowed, flexibleAllowed: $flexibleAllowed, releaseNotes: $releaseNotes)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UpdateInfo &&
        other.versionCode == versionCode &&
        other.availableVersion == availableVersion &&
        other.currentVersion == currentVersion &&
        other.releaseNotes == releaseNotes &&
        other.appStoreUrl == appStoreUrl &&
        other.source == source &&
        other.availability == availability &&
        other.priority == priority &&
        other.immediateAllowed == immediateAllowed &&
        other.flexibleAllowed == flexibleAllowed &&
        other.clientVersionStalenessDays == clientVersionStalenessDays &&
        other.installStatus == installStatus &&
        other.bytesDownloaded == bytesDownloaded &&
        other.totalBytesToDownload == totalBytesToDownload;
  }

  @override
  int get hashCode {
    return Object.hash(
      versionCode,
      availableVersion,
      currentVersion,
      releaseNotes,
      appStoreUrl,
      source,
      availability,
      priority,
      immediateAllowed,
      flexibleAllowed,
      clientVersionStalenessDays,
      installStatus,
      bytesDownloaded,
      totalBytesToDownload,
    );
  }
}
