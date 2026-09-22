/// Configuration options for the in-app update checking and installation process.
class InAppUpdateConfig {
  /// The minimum acceptable version. If the available version is lower than this,
  /// the update might be ignored depending on your custom logic.
  final String? minimumVersion;

  /// The recommended version. If the available version matches or exceeds this,
  /// a flexible update might be suggested.
  final String? recommendedVersion;

  /// Whether to force an immediate update if an update is available.
  final bool forceUpdate;

  /// Whether to automatically check for updates on application startup.
  final bool checkOnStartup;

  /// The maximum duration to wait for a response when checking for an update.
  final Duration timeout;

  /// Creates a new [InAppUpdateConfig] instance.
  const InAppUpdateConfig({
    this.minimumVersion,
    this.recommendedVersion,
    this.forceUpdate = false,
    this.checkOnStartup = true,
    this.timeout = const Duration(seconds: 30),
  });

  /// Creates an [InAppUpdateConfig] from a Map.
  factory InAppUpdateConfig.fromMap(Map<String, dynamic> map) {
    return InAppUpdateConfig(
      minimumVersion: map['minimumVersion'] as String?,
      recommendedVersion: map['recommendedVersion'] as String?,
      forceUpdate: map['forceUpdate'] as bool? ?? false,
      checkOnStartup: map['checkOnStartup'] as bool? ?? true,
      timeout: map['timeoutMs'] != null 
          ? Duration(milliseconds: map['timeoutMs'] as int)
          : const Duration(seconds: 30),
    );
  }

  /// Converts the [InAppUpdateConfig] instance to a Map.
  Map<String, dynamic> toMap() {
    return {
      'minimumVersion': minimumVersion,
      'recommendedVersion': recommendedVersion,
      'forceUpdate': forceUpdate,
      'checkOnStartup': checkOnStartup,
      'timeoutMs': timeout.inMilliseconds,
    };
  }
}
