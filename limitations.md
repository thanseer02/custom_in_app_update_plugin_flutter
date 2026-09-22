# Limitations

## Cross-Platform Differences
The biggest limitation of an in-app updates plugin is the fundamental difference in how Android and iOS handle app updates.

### Android
- **Native Support**: Android has first-party support for in-app updates via the Google Play Core API.
- **Update Types**: Supports both `Flexible` (background download while using app) and `Immediate` (blocking full-screen UI).
- **Progress Tracking**: Provides detailed byte-level download progress and status events.
- **Staleness/Priority**: Google Play Console allows setting an update priority, and the API returns how many days the update has been available.
- **Limitation**: Must be distributed via Google Play Store. Will not work for side-loaded apps or other app stores.

### iOS
- **No Native In-App Update UI**: Apple does not provide a system-level API that shows an update dialog and installs the app while it runs in the foreground.
- **Checking for Updates**: Relies on querying the public iTunes Lookup API. This can sometimes be cached or slightly delayed compared to the actual App Store.
- **Action**: The best an app can do is detect a version difference and direct the user to the App Store app (`itms-apps://`) to perform the update.
- **Update Types**: Flexible and Immediate flows are simulated purely by the Flutter app's UI (e.g., showing a blocking dialog for "immediate" or a soft banner for "flexible").
- **Progress Tracking**: Not possible. Once the user is sent to the App Store, the app loses control.

## Conclusion
The plugin must clearly document that `startFlexibleUpdate()`, `startImmediateUpdate()`, and `completeFlexibleUpdate()` are inherently Android-specific mechanisms. On iOS, developers must use `checkForUpdate()` and `openStore()` combined with their own custom Flutter UI to prompt the user.
