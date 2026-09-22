/// Represents the installation status of a flexible update.
enum UpdateInstallStatus {
  /// The install status is unknown.
  unknown,

  /// The update is pending.
  pending,

  /// The update is downloading.
  downloading,

  /// The update has been downloaded and is ready to be installed.
  downloaded,

  /// The update is currently being installed.
  installing,

  /// The update has been successfully installed.
  installed,

  /// The update failed to install.
  failed,

  /// The update was canceled by the user.
  canceled,
}
