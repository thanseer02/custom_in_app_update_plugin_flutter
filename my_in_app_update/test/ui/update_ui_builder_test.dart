import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_in_app_update/my_in_app_update.dart';
import 'package:my_in_app_update/my_in_app_update_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPlatformWithUpdate with MockPlatformInterfaceMixin implements MyInAppUpdatePlatform {
  bool immediateTriggered = false;
  bool flexibleTriggered = false;
  bool appStoreOpened = false;
  String? openedUrl;

  @override
  Stream<DownloadProgress> get downloadProgressStream => const Stream.empty();

  @override
  Future<String?> getPlatformVersion() => Future.value('1.0');

  @override
  Future<UpdateInfo> checkForUpdate({
    String? iosBundleId,
    String? iosCountryCode,
  }) => Future.value(
        const UpdateInfo(
          versionCode: 15,
          availability: UpdateAvailability.available,
          immediateAllowed: true,
          flexibleAllowed: true,
        ),
      );

  @override
  Future<Map<String, dynamic>?> getAppInfo() => Future.value({
        'bundleId': 'com.example.app',
        'currentVersion': '1.0.0',
        'buildNumber': '1',
      });

  @override
  Future<bool> openAppStore(String url) {
    appStoreOpened = true;
    openedUrl = url;
    return Future.value(true);
  }

  @override
  Future<void> startImmediateUpdate() {
    immediateTriggered = true;
    return Future.value();
  }

  @override
  Future<void> performImmediateUpdate() => startImmediateUpdate();

  @override
  Future<void> startFlexibleUpdate({void Function(UpdateInfo updateInfo)? onProgress}) {
    flexibleTriggered = true;
    return Future.value();
  }

  @override
  Future<void> completeFlexibleUpdate() => Future.value();
}

void main() {
  testWidgets('checkForUpdate renders custom uiBuilder and responds to onUpdate', (tester) async {
    final mockPlatform = MockPlatformWithUpdate();
    MyInAppUpdatePlatform.instance = mockPlatform;
    final plugin = MyInAppUpdate();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  plugin.checkForUpdate(
                    context: context,
                    uiBuilder: (ctx, info, onUpdate, onDismiss) {
                      return AlertDialog(
                        title: Text('Update Available: v${info.versionCode}'),
                        actions: [
                          TextButton(onPressed: onDismiss, child: const Text('Later')),
                          TextButton(onPressed: onUpdate, child: const Text('Update Now')),
                        ],
                      );
                    },
                  );
                },
                child: const Text('Check for Updates'),
              );
            },
          ),
        ),
      ),
    );

    // Tap button to check for updates
    await tester.tap(find.text('Check for Updates'));
    await tester.pumpAndSettle();

    // Verify dialog was built by custom uiBuilder
    expect(find.text('Update Available: v15'), findsOneWidget);
    expect(find.text('Later'), findsOneWidget);
    expect(find.text('Update Now'), findsOneWidget);

    // Tap onUpdate
    await tester.tap(find.text('Update Now'));
    await tester.pumpAndSettle();

    expect(mockPlatform.immediateTriggered, isTrue);
  });

  testWidgets('UpdatePromptBuilder renders custom banner and handles onDismiss', (tester) async {
    final mockPlatform = MockPlatformWithUpdate();
    MyInAppUpdatePlatform.instance = mockPlatform;
    final plugin = MyInAppUpdate();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UpdatePromptBuilder(
            plugin: plugin,
            builder: (context, info, onUpdate, onDismiss) {
              return Container(
                key: const Key('custom_banner'),
                child: Row(
                  children: [
                    Text('New version ${info.versionCode} is here!'),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: onDismiss,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const Key('custom_banner')), findsOneWidget);
    expect(find.text('New version 15 is here!'), findsOneWidget);

    // Dismiss banner
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('custom_banner')), findsNothing);
  });

  testWidgets('checkForUpdate uses defaultUiBuilder when no uiBuilder is passed', (tester) async {
    final mockPlatform = MockPlatformWithUpdate();
    MyInAppUpdatePlatform.instance = mockPlatform;
    final plugin = MyInAppUpdate();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  plugin.checkForUpdate(context: context);
                },
                child: const Text('Check Update Default'),
              );
            },
          ),
        ),
      ),
    );

    // Tap button to check for updates with default UI
    await tester.tap(find.text('Check Update Default'));
    await tester.pumpAndSettle();

    // Verify default AlertDialog contents
    expect(find.text('Update Available'), findsOneWidget);
    expect(find.textContaining('A new version (15) is available'), findsOneWidget);
    expect(find.text('Later'), findsOneWidget);
    expect(find.text('Update Now'), findsOneWidget);

    // Tap Later to dismiss
    await tester.tap(find.text('Later'));
    await tester.pumpAndSettle();

    expect(find.text('Update Available'), findsNothing);
  });

  testWidgets('promptUpdate redirects to App Store when source is appStore', (tester) async {
    final mockPlatform = MockPlatformWithUpdate();
    MyInAppUpdatePlatform.instance = mockPlatform;
    final plugin = MyInAppUpdate();

    const iosInfo = UpdateInfo(
      versionCode: 123456789,
      availableVersion: '2.5.0',
      currentVersion: '2.4.0',
      source: UpdateSource.appStore,
      appStoreUrl: 'https://apps.apple.com/app/id123456789',
      availability: UpdateAvailability.available,
      flexibleAllowed: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  plugin.promptUpdate(
                    context: context,
                    info: iosInfo,
                  );
                },
                child: const Text('Show iOS Update'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show iOS Update'));
    await tester.pumpAndSettle();

    expect(find.text('Update Available'), findsOneWidget);

    // Tap Download (Update) button
    await tester.tap(find.text('Download'));
    await tester.pumpAndSettle();

    expect(mockPlatform.appStoreOpened, isTrue);
    expect(mockPlatform.openedUrl, 'https://apps.apple.com/app/id123456789');
  });
}
