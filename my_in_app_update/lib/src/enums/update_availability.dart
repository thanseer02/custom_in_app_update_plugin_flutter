/// Represents whether an update is available from the platform store.
enum UpdateAvailability {
  /// Availability is unknown.
  unknown(0),

  /// No update is available for this app.
  notAvailable(1),

  /// An update is available.
  available(2),

  /// An update flow triggered by the developer is currently in progress.
  developerTriggeredUpdateInProgress(3);

  final int value;
  const UpdateAvailability(this.value);

  /// Resolves an [UpdateAvailability] from an integer code.
  static UpdateAvailability fromValue(int? value) {
    return UpdateAvailability.values.firstWhere(
      (e) => e.value == value,
      orElse: () => UpdateAvailability.unknown,
    );
  }
}
