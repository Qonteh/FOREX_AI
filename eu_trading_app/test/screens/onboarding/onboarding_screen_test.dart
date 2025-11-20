import 'package:flutter_test/flutter_test.dart';
import 'package:eu_trading_app/screens/onboarding/onboarding_screen.dart';

void main() {
  testWidgets('Onboarding Screen displays correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));
    expect(find.byType(OnboardingScreen), findsOneWidget);
  });
}