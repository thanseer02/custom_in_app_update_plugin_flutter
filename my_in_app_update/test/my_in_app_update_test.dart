import 'package:flutter_test/flutter_test.dart';
import 'package:my_in_app_update/my_in_app_update.dart';
import 'package:my_in_app_update/my_in_app_update_platform_interface.dart';
import 'package:my_in_app_update/my_in_app_update_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockMyInAppUpdatePlatform
    with MockPlatformInterfaceMixin
    implements MyInAppUpdatePlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
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
}
