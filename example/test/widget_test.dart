import 'package:custom_app_update_example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('download survives sheet dismissal and appears in other surfaces',
      (tester) async {
    await tester.pumpWidget(const UpdateExample(demoMode: true));
    await tester.pumpAndSettle();
    expect(find.textContaining('DEMO MODE'), findsOneWidget);
    await tester.tap(find.text('Bottom sheet'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Download update'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    await tester.tap(find.text('Continue using app'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Dialog'));
    // Determinate progress does not schedule continuous frames. Advance the
    // fake clock through each simulated network tick explicitly.
    for (var tick = 0; tick < 24; tick++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    await tester.pumpAndSettle();
    expect(find.text('Finish demo installation'), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Full screen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Finish demo installation'));
    await tester.pumpAndSettle();
    expect(find.text('Your update is installed.'), findsOneWidget);
  });

  testWidgets('demo cancellation lets the user try again', (tester) async {
    await tester.pumpWidget(const UpdateExample(demoMode: true));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dialog'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Download update'));
    await tester.pumpAndSettle();
    expect(
        find.text('Update canceled. You can try again later.'), findsOneWidget);
    expect(find.text('Download update'), findsOneWidget);
  });
}
