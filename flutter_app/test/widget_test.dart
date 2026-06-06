import 'package:flutter_test/flutter_test.dart';

import 'package:cooking_app/main.dart';

void main() {
  testWidgets('App builds without crashing', (WidgetTester tester) async {
    // Build the app with onboarding disabled and trigger a frame.
    await tester.pumpWidget(const PickishApp(showOnboarding: false));

    // Verify the app renders the title
    expect(find.text('Pickish'), findsOneWidget);
  });
}
