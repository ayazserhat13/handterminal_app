import 'package:flutter_test/flutter_test.dart';

import 'package:handterminal_app/main.dart';
import 'package:handterminal_app/splash_screen.dart';

void main() {
  testWidgets('App starts on splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const LcdApp());

    expect(find.byType(SplashScreen), findsOneWidget);
  });
}
