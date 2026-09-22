/// Specifies the source to check for app updates.
enum UpdateSource {
  /// Check the official platform store (Google Play or Apple App Store).
  store,

  /// Check a custom remote JSON endpoint.
  remote,

  /// Custom source, e.g. a manual check or other integration.
  custom,
}
