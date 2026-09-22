/// Represents the progress and status of an ongoing update installation.
enum UpdateInstallStatus {
  /// The install status is unknown.
  unknown,

  /// The update is pending and hasn't started downloading yet.
  pending,

  /// The update is currently being downloaded.
  downloading,

  /// The update has been successfully downloaded and is ready to be installed.
  downloaded,

  /// The update is currently being installed.
  installing,

  /// The update has been successfully installed.
  installed,

  /// The update failed to install.
  failed,

  /// The update installation was canceled by the user or the system.
  canceled,
}
