/// The current lifecycle state of an update check / flow.
enum UpdateStatus {
  /// Still checking for an update (Play Store / App Store lookup in flight).
  checking,

  /// An update is available but no flow has been started yet.
  available,

  /// No update is available; app is up to date.
  notAvailable,

  /// A flexible update is downloading in the background.
  downloading,

  /// A flexible update finished downloading and is ready to install.
  downloaded,

  /// Something went wrong while checking or updating.
  error,
}

/// Coarse update urgency, mirrors Play Console's `inAppUpdatePriority`
/// (0-5) collapsed into three buckets consumers can branch on easily.
enum UpdatePriority { low, medium, high }

/// Platform-agnostic snapshot of update availability.
///
/// Whether it came from Google Play's In-App Update API (Android) or an
/// App Store version lookup (iOS), consumers only ever deal with this one
/// shape, so a single custom UI can serve both platforms.
class UpdateInfo {
  const UpdateInfo({
    required this.status,
    required this.updateAvailable,
    this.availableVersion,
    this.installedVersion,
    this.priority = UpdatePriority.low,
    this.immediateAllowed = false,
    this.flexibleAllowed = false,
    this.downloadProgress,
    this.errorMessage,
  });

  /// Current lifecycle status of this update.
  final UpdateStatus status;

  /// Whether a newer version exists.
  final bool updateAvailable;

  /// Human-readable version string of the update, if known
  /// (versionCode on Android, marketing version on iOS).
  final String? availableVersion;

  /// The version currently installed on the device.
  final String? installedVersion;

  /// Urgency bucket — use this to decide immediate vs flexible vs "later".
  final UpdatePriority priority;

  /// Android only: whether an immediate (blocking, full-screen) flow
  /// is allowed for this update.
  final bool immediateAllowed;

  /// Android only: whether a flexible (background) flow is allowed.
  final bool flexibleAllowed;

  /// 0-100 while [status] is [UpdateStatus.downloading].
  final int? downloadProgress;

  /// Populated when [status] is [UpdateStatus.error].
  final String? errorMessage;

  UpdateInfo copyWith({
    UpdateStatus? status,
    bool? updateAvailable,
    String? availableVersion,
    String? installedVersion,
    UpdatePriority? priority,
    bool? immediateAllowed,
    bool? flexibleAllowed,
    int? downloadProgress,
    String? errorMessage,
  }) {
    return UpdateInfo(
      status: status ?? this.status,
      updateAvailable: updateAvailable ?? this.updateAvailable,
      availableVersion: availableVersion ?? this.availableVersion,
      installedVersion: installedVersion ?? this.installedVersion,
      priority: priority ?? this.priority,
      immediateAllowed: immediateAllowed ?? this.immediateAllowed,
      flexibleAllowed: flexibleAllowed ?? this.flexibleAllowed,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  String toString() =>
      'UpdateInfo(status: $status, updateAvailable: $updateAvailable, '
      'available: $availableVersion, installed: $installedVersion, '
      'priority: $priority, immediate: $immediateAllowed, '
      'flexible: $flexibleAllowed, progress: $downloadProgress)';
}
