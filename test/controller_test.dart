import 'dart:async';

import 'package:custom_app_update/custom_app_update.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

AppUpdateInfo available({
  InstallStatus status = InstallStatus.unknown,
  bool allowed = true,
}) => AppUpdateInfo(
  updateAvailability: UpdateAvailability.updateAvailable,
  immediateUpdateAllowed: true,
  immediateAllowedPreconditions: null,
  flexibleUpdateAllowed: allowed,
  flexibleAllowedPreconditions: null,
  availableVersionCode: 12,
  installStatus: status,
  packageName: 'example.app',
  clientVersionStalenessDays: 1,
  updatePriority: 0,
);

class FakeBackend implements UpdateBackend {
  @override
  bool isSupported = true;
  final events = StreamController<UpdateInstallState>.broadcast(sync: true);
  AppUpdateInfo info = available();
  Completer<AppUpdateInfo>? checkResult;
  final result = Completer<AppUpdateResult>();
  int downloads = 0;
  int installs = 0;
  Object? installError;

  @override
  Stream<UpdateInstallState> get statuses => events.stream;
  @override
  Future<AppUpdateInfo> check() async =>
      checkResult == null ? info : await checkResult!.future;
  @override
  Future<AppUpdateResult> download() {
    downloads++;
    return result.future;
  }

  @override
  Future<void> install() async {
    installs++;
    if (installError != null) throw installError!;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeBackend backend;
  late CustomAppUpdateController controller;
  setUp(() {
    backend = FakeBackend();
    controller = CustomAppUpdateController(backend: backend);
  });
  tearDown(() async {
    controller.dispose();
    await backend.events.close();
  });

  test(
    'download needs eligibility and duplicate taps start only once',
    () async {
      await controller.download();
      expect(backend.downloads, 0);
      await controller.check();
      final download = controller.download();
      await Future<void>.delayed(Duration.zero);
      await controller.download();
      expect(backend.downloads, 1);
      backend.events.add(const UpdateInstallState(status: InstallStatus.downloading));
      expect(controller.phase, UpdatePhase.downloading);
      backend.result.complete(AppUpdateResult.success);
      await download;
      expect(controller.canInstall, isTrue);
      expect(backend.installs, 0); // Never auto-install.
      await controller.restartAndInstall();
      expect(backend.installs, 1);
    },
  );

  test('user cancellation is not treated as failure', () async {
    await controller.check();
    backend.result.complete(AppUpdateResult.userDeniedUpdate);
    await controller.download();
    expect(controller.phase, UpdatePhase.canceled);
    expect(controller.error, isNull);
    expect(controller.canDownload, isTrue);
  });

  test('resume recovers a downloaded update without prompting', () async {
    backend.info = available(status: InstallStatus.downloaded);
    controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await controller.check();
    expect(controller.canInstall, isTrue);
    expect(backend.downloads, 0);
    expect(backend.installs, 0);
  });

  test('failed installation keeps restart available for retry', () async {
    backend.info = available(status: InstallStatus.downloaded);
    await controller.check();
    backend.installError = StateError('installation failed');
    await controller.restartAndInstall();
    expect(controller.canInstall, isTrue);
    expect(controller.error, isNotNull);
    backend.installError = null;
    await controller.restartAndInstall();
    expect(backend.installs, 2);
  });

  test('new status wins over an older pending check response', () async {
    await controller.check();
    backend.checkResult = Completer<AppUpdateInfo>();
    final checking = controller.check();
    backend.events.add(const UpdateInstallState(status: InstallStatus.downloaded));
    backend.checkResult!.complete(available());
    await checking;
    expect(controller.canInstall, isTrue);
  });

  test('unsupported platforms never start native calls', () async {
    backend.isSupported = false;
    await controller.check();
    await controller.download();
    expect(controller.phase, UpdatePhase.unsupported);
    expect(backend.downloads, 0);
  });

  test('eligibility is rechecked before presenting Play consent', () async {
    await controller.check();
    backend.info = available(allowed: false);
    await controller.download();
    expect(backend.downloads, 0);
    expect(controller.canDownload, isFalse);
  });

  test('disposing during a check does not notify after disposal', () async {
    final other = CustomAppUpdateController(backend: backend);
    backend.checkResult = Completer<AppUpdateInfo>();
    final checking = other.check();
    other.dispose();
    backend.checkResult!.complete(available());
    await checking;
  });
}
