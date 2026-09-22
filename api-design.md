# API Design

## Enums and Models

```dart
enum UpdateType {
  flexible,
  immediate,
}

enum UpdateAvailability {
  unknown,
  noUpdate,
  updateAvailable,
  developerTriggered,
  updateInProgress,
}

enum UpdateInstallStatus {
  unknown,
  pending,
  downloading,
  downloaded,
  installing,
  installed,
  failed,
  canceled,
}

class UpdateInfo {
  final bool isUpdateAvailable;
  final String currentVersion;
  final String availableVersion;
  final int currentBuildNumber;
  final int availableBuildNumber;
  final bool immediateUpdateAllowed;
  final bool flexibleUpdateAllowed;
  final int? updatePriority; // Android only (0-5)
  final int? clientVersionStalenessDays; // Android only
  final UpdateInstallStatus installStatus;
  final String platform; // 'android' or 'ios'
}

class InAppUpdateConfig {
  final String? minimumVersion;
  final String? recommendedVersion;
  final bool forceUpdate;
  final bool checkOnStartup;
  final Duration timeout;
}
```

## Public Methods

```dart
class FlutterInAppUpdate {
  /// Checks if an update is available on the respective store.
  static Future<UpdateInfo> checkForUpdate();

  /// Starts a flexible update flow (Android only).
  /// Throws PlatformException on iOS or if not allowed.
  static Future<void> startFlexibleUpdate();

  /// Starts an immediate update flow (Android only).
  /// Throws PlatformException on iOS or if not allowed.
  static Future<void> startImmediateUpdate();

  /// Completes a flexible update that has been downloaded (Android only).
  static Future<void> completeFlexibleUpdate();

  /// Opens the app's store page (Play Store / App Store).
  static Future<void> openStore();
  
  /// Stream to listen to update install status (useful for flexible updates).
  static Stream<UpdateInstallStatus> get installStatusStream;
}
```
