/// The type of the update.
enum UpdateType {
  /// A flexible update. This type of update downloads in the background and
  /// allows the user to continue using the app. Once downloaded, the app needs
  /// to be restarted to install the update.
  flexible,

  /// An immediate update. This type of update requires the user to update and
  /// restart the app before they can continue using it.
  immediate,
}
