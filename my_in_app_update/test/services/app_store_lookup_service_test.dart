import 'package:flutter_test/flutter_test.dart';
import 'package:my_in_app_update/my_in_app_update.dart';

void main() {
  group('AppStoreLookupService tests', () {
    test('isVersionNewer correctly identifies newer versions', () {
      expect(AppStoreLookupService.isVersionNewer('2.0.0', '1.0.0'), isTrue);
      expect(AppStoreLookupService.isVersionNewer('1.1.0', '1.0.9'), isTrue);
      expect(AppStoreLookupService.isVersionNewer('1.0.1', '1.0.0'), isTrue);
      expect(AppStoreLookupService.isVersionNewer('v2.1.0', '2.0.9'), isTrue);
      expect(AppStoreLookupService.isVersionNewer('2.0.0+10', '2.0.0+5'), isFalse);
      expect(AppStoreLookupService.isVersionNewer('1.0.0', '1.0.0'), isFalse);
      expect(AppStoreLookupService.isVersionNewer('1.0.0', '2.0.0'), isFalse);
    });

    test('handles empty bundleId gracefully', () async {
      final service = AppStoreLookupService();
      final info = await service.lookup(
        bundleId: '',
        currentVersion: '1.0.0',
      );

      expect(info.availability, UpdateAvailability.unknown);
      expect(info.source, UpdateSource.appStore);
      expect(info.isUpdateAvailable, isFalse);
    });
  });

  group('Unified UpdateInfo iOS tests', () {
    test('UpdateInfo deserialization with iOS App Store fields', () {
      final map = {
        'availableVersionCode': 123456789,
        'availableVersion': '3.2.0',
        'currentVersion': '3.1.0',
        'releaseNotes': 'New shiny features and stability improvements',
        'appStoreUrl': 'https://apps.apple.com/app/id123456789',
        'source': 'appStore',
        'updateAvailability': 2,
        'immediateAllowed': false,
        'flexibleAllowed': true,
      };

      final info = UpdateInfo.fromMap(map);
      expect(info.versionCode, 123456789);
      expect(info.availableVersion, '3.2.0');
      expect(info.currentVersion, '3.1.0');
      expect(info.releaseNotes, 'New shiny features and stability improvements');
      expect(info.appStoreUrl, 'https://apps.apple.com/app/id123456789');
      expect(info.source, UpdateSource.appStore);
      expect(info.isUpdateAvailable, isTrue);
    });
  });
}
