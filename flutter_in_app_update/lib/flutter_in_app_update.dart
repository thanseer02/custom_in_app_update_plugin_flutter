
import 'platform/flutter_in_app_update_platform_interface.dart';

class FlutterInAppUpdate {
  Future<String?> getPlatformVersion() {
    return FlutterInAppUpdatePlatform.instance.getPlatformVersion();
  }
}
