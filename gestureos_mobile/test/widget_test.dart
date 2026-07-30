import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gesture_os/app/app.dart';

void main() {
  testWidgets('App renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: GestureOSApp(),
      ),
    );
    // Let splash screen render then advance past the 2.5s splash timer
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    // Timer has now fired; pump one more frame for the navigation
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
