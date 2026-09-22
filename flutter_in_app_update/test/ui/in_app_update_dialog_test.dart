import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_in_app_update/flutter_in_app_update.dart';
import 'package:flutter_in_app_update/ui.dart';

void main() {
  group('InAppUpdateDialog', () {
    final mockUpdateInfo = UpdateInfo(
      isUpdateAvailable: true,
      currentVersion: '1.0.0',
      availableVersion: '2.0.0',
      currentBuildNumber: 1,
      availableBuildNumber: 2,
      immediateUpdateAllowed: true,
      flexibleUpdateAllowed: true,
      installStatus: UpdateInstallStatus.unknown,
      availability: UpdateAvailability.updateAvailable,
      platform: 'android',
    );

    testWidgets('renders mandatory dialog when onLater is null', (WidgetTester tester) async {
      bool updateClicked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InAppUpdateDialog(
              updateInfo: mockUpdateInfo,
              onUpdate: () {
                updateClicked = true;
              },
              // onLater is null, so it's mandatory
            ),
          ),
        ),
      );

      // Verify title defaults to 'Update Required'
      expect(find.text('Update Required'), findsOneWidget);
      // Verify 'Later' button does not exist
      expect(find.text('Later'), findsNothing);
      
      // Tap update button
      await tester.tap(find.text('Update Now'));
      await tester.pumpAndSettle();
      
      expect(updateClicked, isTrue);
    });

    testWidgets('renders optional dialog when onLater is provided', (WidgetTester tester) async {
      bool laterClicked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InAppUpdateDialog(
              updateInfo: mockUpdateInfo,
              onUpdate: () {},
              onLater: () {
                laterClicked = true;
              },
            ),
          ),
        ),
      );

      // Verify title defaults to 'Update Available'
      expect(find.text('Update Available'), findsOneWidget);
      // Verify 'Later' button exists
      expect(find.text('Later'), findsOneWidget);

      // Tap later button
      await tester.tap(find.text('Later'));
      await tester.pumpAndSettle();

      expect(laterClicked, isTrue);
    });

    testWidgets('respects customBuilder completely replacing UI', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InAppUpdateDialog(
              updateInfo: mockUpdateInfo,
              onUpdate: () {},
              customBuilder: (context, info) {
                return const Text('Completely Custom UI');
              },
            ),
          ),
        ),
      );

      expect(find.text('Completely Custom UI'), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
    });
  });
}
