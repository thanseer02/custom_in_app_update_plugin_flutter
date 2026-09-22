import 'package:flutter_test/flutter_test.dart';
import 'package:my_in_app_update/my_in_app_update.dart';

void main() {
  group('UpdateInfo & UpdateStatus tests', () {
    test('UpdateInfo deserialization from map', () {
      final map = {
        'availableVersionCode': 105,
        'updateAvailability': 2,
        'updatePriority': 4,
        'immediateAllowed': true,
        'flexibleAllowed': true,
        'clientVersionStalenessDays': 3,
        'installStatus': 2,
        'bytesDownloaded': 500,
        'totalBytesToDownload': 1000,
      };

      final info = UpdateInfo.fromMap(map);

      expect(info.versionCode, 105);
      expect(info.availability, UpdateAvailability.available);
      expect(info.isUpdateAvailable, isTrue);
      expect(info.priority, 4);
      expect(info.immediateAllowed, isTrue);
      expect(info.flexibleAllowed, isTrue);
      expect(info.clientVersionStalenessDays, 3);
      expect(info.installStatus, 2);
      expect(info.bytesDownloaded, 500);
      expect(info.totalBytesToDownload, 1000);
      expect(info.downloadProgress, 0.5);
    });

    test('UpdateInfo serialization to map', () {
      const info = UpdateInfo(
        versionCode: 200,
        availability: UpdateAvailability.notAvailable,
        priority: 1,
        immediateAllowed: false,
        flexibleAllowed: false,
      );

      final map = info.toMap();
      expect(map['versionCode'], 200);
      expect(map['availability'], 1);
      expect(map['priority'], 1);
      expect(map['immediateAllowed'], isFalse);
      expect(map['flexibleAllowed'], isFalse);
    });

    test('UpdateInfo copyWith', () {
      const info = UpdateInfo(
        versionCode: 100,
        availability: UpdateAvailability.available,
        priority: 2,
        immediateAllowed: true,
        flexibleAllowed: false,
      );

      final updated = info.copyWith(
        flexibleAllowed: true,
        bytesDownloaded: 250,
        totalBytesToDownload: 500,
      );

      expect(updated.versionCode, 100);
      expect(updated.flexibleAllowed, isTrue);
      expect(updated.bytesDownloaded, 250);
      expect(updated.totalBytesToDownload, 500);
      expect(updated.downloadProgress, 0.5);
    });

    test('UpdateStatus enum contains all required states', () {
      expect(UpdateStatus.values, containsAll([
        UpdateStatus.checking,
        UpdateStatus.available,
        UpdateStatus.downloading,
        UpdateStatus.downloaded,
        UpdateStatus.notAvailable,
        UpdateStatus.error,
      ]));
    });
  });
}
