import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_in_app_update/flutter_in_app_update.dart';
import '../mocks/mock_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Android In-App Update Platform Tests', () {
    tearDown(() {
      MockMethodChannel.reset();
    });

    test('no update available', () async {
      MockMethodChannel.setUpdateAvailableResponse(
        isUpdateAvailable: false,
        currentVersion: '1.0.0',
        availableVersion: '1.0.0',
        availability: UpdateAvailability.noUpdate.index,
        platform: 'android',
      );

      final updateInfo = await FlutterInAppUpdate.checkForUpdate();

      expect(updateInfo.isUpdateAvailable, isFalse);
      expect(updateInfo.currentVersion, '1.0.0');
      expect(updateInfo.availableVersion, '1.0.0');
      expect(updateInfo.availability, UpdateAvailability.noUpdate);
      expect(updateInfo.platform, 'android');
    });

    test('update available', () async {
      MockMethodChannel.setUpdateAvailableResponse(
        isUpdateAvailable: true,
        currentVersion: '1.0.0',
        availableVersion: '2.0.0',
        flexibleUpdateAllowed: true,
        immediateUpdateAllowed: true,
        availability: UpdateAvailability.updateAvailable.index,
        platform: 'android',
      );

      final updateInfo = await FlutterInAppUpdate.checkForUpdate();

      expect(updateInfo.isUpdateAvailable, isTrue);
      expect(updateInfo.currentVersion, '1.0.0');
      expect(updateInfo.availableVersion, '2.0.0');
      expect(updateInfo.flexibleUpdateAllowed, isTrue);
      expect(updateInfo.immediateUpdateAllowed, isTrue);
      expect(updateInfo.availability, UpdateAvailability.updateAvailable);
    });

    test('start flexible update flow succeeds', () async {
      MockMethodChannel.setUpdateAvailableResponse();

      expect(FlutterInAppUpdate.startFlexibleUpdate(), completes);
    });

    test('start immediate update flow succeeds', () async {
      MockMethodChannel.setUpdateAvailableResponse();

      expect(FlutterInAppUpdate.startImmediateUpdate(), completes);
    });

    test('canceled update mapped to InAppUpdateErrorCode.updateCanceled', () async {
      MockMethodChannel.setPlatformErrorResponse(
        code: 'CANCELED',
        message: 'User canceled flexible update',
      );

      expect(
        () => FlutterInAppUpdate.startFlexibleUpdate(),
        throwsA(
          isA<InAppUpdateException>().having(
            (e) => e.code,
            'code',
            InAppUpdateErrorCode.updateCanceled,
          ),
        ),
      );
    });

    test('failed update mapped to InAppUpdateErrorCode.updateFailed', () async {
      MockMethodChannel.setPlatformErrorResponse(
        code: 'FAILED',
        message: 'Flexible update failed',
      );

      expect(
        () => FlutterInAppUpdate.startFlexibleUpdate(),
        throwsA(
          isA<InAppUpdateException>().having(
            (e) => e.code,
            'code',
            InAppUpdateErrorCode.updateFailed,
          ),
        ),
      );
    });

    test('downloaded update status reported in UpdateInfo', () async {
      MockMethodChannel.setUpdateAvailableResponse(
        installStatus: UpdateInstallStatus.downloaded.index,
        availability: UpdateAvailability.developerTriggered.index,
      );

      final updateInfo = await FlutterInAppUpdate.checkForUpdate();

      expect(updateInfo.installStatus, UpdateInstallStatus.downloaded);
      expect(updateInfo.availability, UpdateAvailability.developerTriggered);
    });

    test('complete flexible update flow succeeds', () async {
      MockMethodChannel.setUpdateAvailableResponse();

      expect(FlutterInAppUpdate.completeFlexibleUpdate(), completes);
    });
  });
}
