import 'package:flutter_test/flutter_test.dart';

import 'package:gesture_os/app/app.dart';

void main() {
  testWidgets('App renders', (WidgetTester tester) async {
    await tester.pumpWidget(const GestureOSApp());
    expect(find.byType(GestureOSApp), findsOneWidget);
  });
}
