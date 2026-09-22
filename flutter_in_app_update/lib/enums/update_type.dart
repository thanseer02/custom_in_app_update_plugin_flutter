/// Defines the type of update being requested or available.
enum UpdateType {
  /// A flexible update allows the user to continue using the app while the
  /// update is being downloaded in the background. Once downloaded, the user
  /// can be prompted to install it.
  flexible,

  /// An immediate update forces the user to wait for the update to download
  /// and install before they can continue using the app. This is useful for
  /// critical updates.
  immediate,
}
