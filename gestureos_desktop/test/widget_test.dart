import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestureos_desktop/main.dart';

void main() {
  testWidgets('App renders', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: GestureOSApp()));
    expect(find.text('GestureOS'), findsOneWidget);
  });
}
