import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_in_app_update_example/main.dart';

void main() {
  testWidgets('Renders InAppUpdateDemoPage with 3 showcase patterns', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: InAppUpdateDemoPage(),
    ));

    expect(find.text('In-App Update Showcase'), findsOneWidget);
    expect(find.text('1. Default Built-in UI'), findsOneWidget);
    expect(find.text('2. Custom AlertDialog UI'), findsOneWidget);
    expect(find.text('3. Custom Bottom Sheet & Live Stream'), findsOneWidget);
  });
}
