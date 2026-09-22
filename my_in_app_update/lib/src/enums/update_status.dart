/// Represents the current status of the in-app update lifecycle.
enum UpdateStatus {
  /// Checking with store/remote for update availability.
  checking,

  /// An update is available to download/install.
  available,

  /// An update is currently being downloaded.
  downloading,

  /// The update download has completed and is ready to install.
  downloaded,

  /// No update is available (app is up to date).
  notAvailable,

  /// An error occurred during check or update flow.
  error,
}
