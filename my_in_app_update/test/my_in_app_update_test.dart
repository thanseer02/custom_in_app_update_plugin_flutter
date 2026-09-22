import 'package:flutter_test/flutter_test.dart';
import 'package:my_in_app_update/my_in_app_update.dart';
import 'package:my_in_app_update/my_in_app_update_platform_interface.dart';
import 'package:my_in_app_update/my_in_app_update_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockMyInAppUpdatePlatform
    with MockPlatformInterfaceMixin
    implements MyInAppUpdatePlatform {
  @override
  Stream<DownloadProgress> get downloadProgressStream => Stream.value(
        const DownloadProgress(
          bytesDownloaded: 50,
          totalBytesToDownload: 100,
          installStatus: 2,
        ),
      );

  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<UpdateInfo> checkForUpdate({
    String? iosBundleId,
    String? iosCountryCode,
  }) => Future.value(
        const UpdateInfo(
          versionCode: 10,
          availability: UpdateAvailability.available,
          priority: 3,
          immediateAllowed: true,
          flexibleAllowed: true,
        ),
      );

  @override
  Future<Map<String, dynamic>?> getAppInfo() => Future.value({
        'bundleId': 'com.example.app',
        'currentVersion': '1.0.0',
        'buildNumber': '1',
        'appName': 'Example App',
      });

  @override
  Future<bool> openAppStore(String url) => Future.value(true);

  @override
  Future<void> startImmediateUpdate() => Future.value();

  @override
  Future<void> performImmediateUpdate() => Future.value();

  @override
  Future<void> startFlexibleUpdate({void Function(UpdateInfo updateInfo)? onProgress}) {
    onProgress?.call(
      const UpdateInfo(
        versionCode: 10,
        availability: UpdateAvailability.available,
        bytesDownloaded: 50,
        totalBytesToDownload: 100,
      ),
    );
    return Future.value();
  }

  @override
  Future<void> completeFlexibleUpdate() => Future.value();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final MyInAppUpdatePlatform initialPlatform = MyInAppUpdatePlatform.instance;

  test('$MethodChannelMyInAppUpdate is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelMyInAppUpdate>());
  });

  test('getPlatformVersion', () async {
    MyInAppUpdate myInAppUpdatePlugin = MyInAppUpdate();
    MockMyInAppUpdatePlatform fakePlatform = MockMyInAppUpdatePlatform();
    MyInAppUpdatePlatform.instance = fakePlatform;

    expect(await myInAppUpdatePlugin.getPlatformVersion(), '42');
  });

  test('checkForUpdate', () async {
    MyInAppUpdate myInAppUpdatePlugin = MyInAppUpdate();
    MockMyInAppUpdatePlatform fakePlatform = MockMyInAppUpdatePlatform();
    MyInAppUpdatePlatform.instance = fakePlatform;

    final info = await myInAppUpdatePlugin.checkForUpdate();
    expect(info.versionCode, 10);
    expect(info.availability, UpdateAvailability.available);
    expect(info.priority, 3);
    expect(info.immediateAllowed, isTrue);
    expect(info.flexibleAllowed, isTrue);
  });

  test('downloadProgressStream emits progress', () async {
    MyInAppUpdate myInAppUpdatePlugin = MyInAppUpdate();
    MockMyInAppUpdatePlatform fakePlatform = MockMyInAppUpdatePlatform();
    MyInAppUpdatePlatform.instance = fakePlatform;

    final progress = await myInAppUpdatePlugin.downloadProgressStream.first;
    expect(progress.bytesDownloaded, 50);
    expect(progress.totalBytesToDownload, 100);
    expect(progress.percentage, 50.0);
  });
}
