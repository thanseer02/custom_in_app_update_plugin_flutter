/// Indicates the availability of an update.
enum UpdateAvailability {
  /// The update availability is unknown or there was an error checking for an update.
  unknown,

  /// No update is currently available.
  noUpdate,

  /// An update is available to be downloaded and installed.
  updateAvailable,

  /// An update was triggered by the developer (e.g., via Play Console).
  developerTriggered,

  /// An update is currently in progress (downloading or installing).
  updateInProgress,
}
