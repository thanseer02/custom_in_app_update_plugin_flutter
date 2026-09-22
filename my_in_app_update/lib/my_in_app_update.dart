
import 'my_in_app_update_platform_interface.dart';

class MyInAppUpdate {
  Future<String?> getPlatformVersion() {
    return MyInAppUpdatePlatform.instance.getPlatformVersion();
  }
}
