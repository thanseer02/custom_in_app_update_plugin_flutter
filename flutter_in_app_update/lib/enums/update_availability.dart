/// Represents the availability of an update.
enum UpdateAvailability {
  /// The availability of an update is unknown.
  unknown,

  /// No update is available.
  noUpdate,

  /// An update is available.
  updateAvailable,

  /// An update is already in progress, triggered by the developer.
  developerTriggered,

  /// An update is currently in progress.
  updateInProgress,
}
