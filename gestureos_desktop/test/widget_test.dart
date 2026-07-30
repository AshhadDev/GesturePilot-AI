import 'package:flutter_test/flutter_test.dart';
import 'package:gestureos_desktop/main.dart';

void main() {
  testWidgets('App renders', (WidgetTester tester) async {
    await tester.pumpWidget(const GestureOSApp());
    expect(find.text('GestureOS'), findsOneWidget);
  });
}
