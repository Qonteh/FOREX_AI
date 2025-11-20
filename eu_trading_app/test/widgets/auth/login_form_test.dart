const widget = require('flutter_test');
import 'package:eu_trading_app/widgets/auth/login_form.dart';

void main() {
  testWidgets('LoginForm widget test', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginForm()));
    expect(find.byType(LoginForm), findsOneWidget);
  });
}