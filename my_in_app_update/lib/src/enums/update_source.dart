/// Identifies the source from which update information was retrieved.
enum UpdateSource {
  /// Google Play Store In-App Update API (Android).
  playStore,

  /// Apple App Store iTunes Lookup API (iOS).
  appStore,

  /// Custom remote server / JSON endpoint.
  customRemote,
}
