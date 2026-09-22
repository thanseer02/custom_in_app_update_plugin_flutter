/// Configuration for the in-app update process.
class InAppUpdateConfig {
  /// The minimum version required to run the app. If the store version is
  /// greater than this, the user might be forced to update.
  final String? minimumVersion;

  /// The recommended version. Useful to show an optional update prompt.
  final String? recommendedVersion;

  /// The latest available version on the backend or store. If provided, this overrides
  /// the version fetched natively.
  final String? latestVersion;

  /// Whether the update should be forced, completely blocking the user.
  final bool forceUpdate;

  /// Whether the app should check for updates on startup automatically.
  final bool checkOnStartup;

  /// The interval between automatic update checks.
  final Duration? checkInterval;

  /// Timeout for the update check network request.
  final Duration timeout;

  const InAppUpdateConfig({
    this.minimumVersion,
    this.recommendedVersion,
    this.latestVersion,
    this.forceUpdate = false,
    this.checkOnStartup = true,
    this.checkInterval,
    this.timeout = const Duration(seconds: 15),
  });
}
