import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_in_app_update/my_in_app_update.dart';
import 'package:my_in_app_update/my_in_app_update_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPlatformWithUpdate with MockPlatformInterfaceMixin implements MyInAppUpdatePlatform {
  bool immediateTriggered = false;
  bool flexibleTriggered = false;

  @override
  Stream<DownloadProgress> get downloadProgressStream => const Stream.empty();

  @override
  Future<String?> getPlatformVersion() => Future.value('1.0');

  @override
  Future<UpdateInfo> checkForUpdate() => Future.value(
        const UpdateInfo(
          versionCode: 15,
          availability: UpdateAvailability.available,
          immediateAllowed: true,
          flexibleAllowed: true,
        ),
      );

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
}
