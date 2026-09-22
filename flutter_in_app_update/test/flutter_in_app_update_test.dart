import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_in_app_update/flutter_in_app_update.dart';
import 'package:flutter_in_app_update/platform/flutter_in_app_update_platform_interface.dart';
import 'package:flutter_in_app_update/platform/flutter_in_app_update_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterInAppUpdatePlatform
    with MockPlatformInterfaceMixin
    implements FlutterInAppUpdatePlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final FlutterInAppUpdatePlatform initialPlatform = FlutterInAppUpdatePlatform.instance;

  test('$MethodChannelFlutterInAppUpdate is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFlutterInAppUpdate>());
  });

  test('getPlatformVersion', () async {
    FlutterInAppUpdate flutterInAppUpdatePlugin = FlutterInAppUpdate();
    MockFlutterInAppUpdatePlatform fakePlatform = MockFlutterInAppUpdatePlatform();
    FlutterInAppUpdatePlatform.instance = fakePlatform;

    expect(await flutterInAppUpdatePlugin.getPlatformVersion(), '42');
  });
}
