import 'package:flutter_test/flutter_test.dart';
import 'package:whatssap_clone/main.dart';

void main() {
  testWidgets('Login screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const WhatsAppCloneApp());

    expect(find.text('WhatsApp Clone'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });
}
