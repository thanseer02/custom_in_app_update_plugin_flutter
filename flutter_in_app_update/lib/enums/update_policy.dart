/// Defines the policy or urgency for an available update.
enum UpdatePolicy {
  /// No update is required or available.
  none,

  /// An update is available, but the user is not required or strongly encouraged to install it.
  optional,

  /// An update is available and recommended (e.g., bug fixes, new features).
  recommended,

  /// An update is mandatory. The app should block the user from continuing without updating.
  mandatory,
}
