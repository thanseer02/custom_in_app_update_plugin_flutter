import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_in_app_update/flutter_in_app_update.dart';
import '../mocks/mock_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('iOS In-App Update Platform Tests', () {
    tearDown(() {
      MockMethodChannel.reset();
    });

    test('current version reported correctly', () async {
      MockMethodChannel.setUpdateAvailableResponse(
        isUpdateAvailable: false,
        currentVersion: '1.4.2',
        availableVersion: '1.4.2',
        availability: UpdateAvailability.noUpdate.index,
        platform: 'ios',
      );

      final updateInfo = await FlutterInAppUpdate.checkForUpdate();

      expect(updateInfo.platform, 'ios');
      expect(updateInfo.currentVersion, '1.4.2');
      expect(updateInfo.availableVersion, '1.4.2');
      expect(updateInfo.isUpdateAvailable, isFalse);
    });

    test('newer version available on iTunes App Store lookup', () async {
      MockMethodChannel.setUpdateAvailableResponse(
        isUpdateAvailable: true,
        currentVersion: '1.0.0',
        availableVersion: '2.1.0',
        availability: UpdateAvailability.updateAvailable.index,
        platform: 'ios',
      );

      final updateInfo = await FlutterInAppUpdate.checkForUpdate();

      expect(updateInfo.platform, 'ios');
      expect(updateInfo.isUpdateAvailable, isTrue);
      expect(updateInfo.currentVersion, '1.0.0');
      expect(updateInfo.availableVersion, '2.1.0');
    });

    test('no update when current version matches App Store', () async {
      MockMethodChannel.setUpdateAvailableResponse(
        isUpdateAvailable: false,
        currentVersion: '2.1.0',
        availableVersion: '2.1.0',
        availability: UpdateAvailability.noUpdate.index,
        platform: 'ios',
      );

      final updateInfo = await FlutterInAppUpdate.checkForUpdate();

      expect(updateInfo.isUpdateAvailable, isFalse);
    });

    test('store lookup failure mapped to InAppUpdateErrorCode.storeUnavailable', () async {
      MockMethodChannel.setPlatformErrorResponse(
        code: 'STORE_UNAVAILABLE',
        message: 'Could not contact iTunes store lookup API',
      );

      expect(
        () => FlutterInAppUpdate.checkForUpdate(),
        throwsA(
          isA<InAppUpdateException>().having(
            (e) => e.code,
            'code',
            InAppUpdateErrorCode.storeUnavailable,
          ),
        ),
      );
    });

    test('network failure mapped to InAppUpdateErrorCode.networkError', () async {
      MockMethodChannel.setPlatformErrorResponse(
        code: 'NETWORK_ERROR',
        message: 'No internet connection available',
      );

      expect(
        () => FlutterInAppUpdate.checkForUpdate(),
        throwsA(
          isA<InAppUpdateException>().having(
            (e) => e.code,
            'code',
            InAppUpdateErrorCode.networkError,
          ),
        ),
      );
    });

    test('App Store unavailable mapped to InAppUpdateErrorCode.storeUnavailable', () async {
      MockMethodChannel.setPlatformErrorResponse(
        code: 'STORE_UNAVAILABLE',
        message: 'App Store is unavailable in this region',
      );

      expect(
        () => FlutterInAppUpdate.openStore(),
        throwsA(
          isA<InAppUpdateException>().having(
            (e) => e.code,
            'code',
            InAppUpdateErrorCode.storeUnavailable,
          ),
        ),
      );
    });

    test('unsupported flexible update on iOS mapped to unsupportedPlatform error', () async {
      MockMethodChannel.setPlatformErrorResponse(
        code: 'UNSUPPORTED_PLATFORM',
        message: 'Flexible updates are not supported on iOS',
      );

      expect(
        () => FlutterInAppUpdate.startFlexibleUpdate(),
        throwsA(
          isA<InAppUpdateException>().having(
            (e) => e.code,
            'code',
            InAppUpdateErrorCode.unsupportedPlatform,
          ),
        ),
      );
    });
  });
}
