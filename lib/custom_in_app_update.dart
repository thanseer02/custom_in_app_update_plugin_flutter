/// A Flutter plugin for Android in-app updates (Play Core In-App Update
/// API) and iOS App Store version checks, with a builder pattern that
/// lets the consuming app render fully custom UI instead of a fixed
/// built-in prompt.
library custom_in_app_update;

export 'src/update_info.dart';
export 'src/custom_in_app_update.dart' show CustomInAppUpdate, UpdateUiBuilder;
