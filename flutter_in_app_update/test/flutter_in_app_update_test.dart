import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_in_app_update/flutter_in_app_update.dart';

void main() {
  group('UpdateInfo Model Serialization', () {
    test('fromJson and toJson should work correctly', () {
      final json = {
        'isUpdateAvailable': true,
        'currentVersion': '1.0.0',
        'availableVersion': '1.2.0',
        'currentBuildNumber': 10,
        'availableBuildNumber': 12,
        'immediateUpdateAllowed': true,
        'flexibleUpdateAllowed': false,
        'updatePriority': 3,
        'clientVersionStalenessDays': 5,
        'installStatus': UpdateInstallStatus.downloading.index,
        'availability': UpdateAvailability.updateAvailable.index,
        'platform': 'android',
      };

      final updateInfo = UpdateInfo.fromJson(json);

      expect(updateInfo.isUpdateAvailable, true);
      expect(updateInfo.currentVersion, '1.0.0');
      expect(updateInfo.availableVersion, '1.2.0');
      expect(updateInfo.currentBuildNumber, 10);
      expect(updateInfo.availableBuildNumber, 12);
      expect(updateInfo.immediateUpdateAllowed, true);
      expect(updateInfo.flexibleUpdateAllowed, false);
      expect(updateInfo.updatePriority, 3);
      expect(updateInfo.clientVersionStalenessDays, 5);
      expect(updateInfo.installStatus, UpdateInstallStatus.downloading);
      expect(updateInfo.availability, UpdateAvailability.updateAvailable);
      expect(updateInfo.platform, 'android');

      final serialized = updateInfo.toJson();
      expect(serialized, json);
    });

    test('fromJson should handle null/invalid enum values safely', () {
      final json = {
        'installStatus': 999, // Invalid index
        'availability': -1, // Invalid index
      };

      final updateInfo = UpdateInfo.fromJson(json);

      expect(updateInfo.installStatus, UpdateInstallStatus.unknown);
      expect(updateInfo.availability, UpdateAvailability.unknown);
    });
  });

}
