const { WidgetTester } = require('flutter_test');
import 'package:flutter/material.dart';
import 'package:eu_trading_app/widgets/ui/custom_button.dart';

void main() {
    testWidgets('CustomButton displays text', (WidgetTester tester) async {
        await tester.pumpWidget(MaterialApp(
            home: Scaffold(
                body: CustomButton(
                    text: 'Click Me',
                    onPressed: () {},
                ),
            ),
        ));

        final buttonFinder = find.text('Click Me');
        expect(buttonFinder, findsOneWidget);
    });
}