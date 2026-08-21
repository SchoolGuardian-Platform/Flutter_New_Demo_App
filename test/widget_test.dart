import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SchoolGuardian smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('School Guardian'),
          ),
        ),
      ),
    );

    expect(find.text('School Guardian'), findsOneWidget);
  });
}