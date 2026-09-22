import 'dart:async';

import 'package:custom_app_update/custom_app_update.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const methods = MethodChannel('dev.customappupdate/methods');
  const events = MethodChannel('dev.customappupdate/events');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final backend = GooglePlayUpdateBackend();

  tearDown(() {
    messenger.setMockMethodCallHandler(methods, null);
    messenger.setMockMethodCallHandler(events, null);
  });

  test('check decodes Android data including 64-bit byte counts', () async {
    messenger.setMockMethodCallHandler(methods, (call) async {
      expect(call.method, 'check');
      return <String, Object?>{
        'updateAvailability': 2,
        'flexibleUpdateAllowed': true,
        'installStatus': 2,
        'packageName': 'dev.example.app',
        'bytesDownloaded': 3000000000,
        'totalBytesToDownload': 4000000000,
        'availableVersionCode': 11,
      };
    });
    final info = await backend.check();
    expect(info.flexibleUpdateAllowed, isTrue);
    expect(info.installStatus, InstallStatus.downloading);
    expect(info.bytesDownloaded, 3000000000);
    expect(info.availableVersionCode, 11);
  });

  test('download distinguishes completed download and rejected consent',
      () async {
    messenger.setMockMethodCallHandler(methods, (_) async => 'downloaded');
    expect(await backend.download(), AppUpdateResult.success);
    messenger.setMockMethodCallHandler(methods, (_) async => 'canceled');
    expect(await backend.download(), AppUpdateResult.userDeniedUpdate);
  });

  test('install forwards native task failures', () async {
    messenger.setMockMethodCallHandler(methods, (call) async {
      expect(call.method, 'install');
      throw PlatformException(code: 'INSTALL_FAILED', details: -6);
    });
    await expectLater(backend.install(), throwsA(isA<PlatformException>()));
  });

  test('empty native response is rejected', () async {
    messenger.setMockMethodCallHandler(methods, (_) async => null);
    await expectLater(backend.check(), throwsA(isA<PlatformException>()));
  });

  test('event channel carries status, bytes, and error code', () async {
    messenger.setMockMethodCallHandler(events, (_) async => null);
    final received = Completer<UpdateInstallState>();
    final subscription = backend.statuses.listen(received.complete);
    await Future<void>.delayed(Duration.zero);
    await messenger.handlePlatformMessage(
      'dev.customappupdate/events',
      const StandardMethodCodec().encodeSuccessEnvelope({
        'installStatus': 2,
        'bytesDownloaded': 50,
        'totalBytesToDownload': 100,
        'errorCode': 0,
      }),
      (_) {},
    );
    final state = await received.future;
    expect(state.status, InstallStatus.downloading);
    expect(state.bytesDownloaded, 50);
    expect(state.totalBytesToDownload, 100);
    await subscription.cancel();
  });
}
