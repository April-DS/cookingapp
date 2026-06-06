import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:cooking_app/main.dart';
import 'package:cooking_app/services/app_state.dart';

void main() {
  testWidgets('App builds without crashing', (WidgetTester tester) async {
    // PickishApp expects a ChangeNotifierProvider<AppState> ancestor
    // (created in main()), so the test must provide one too.
    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>(
        create: (_) => AppState(),
        child: const PickishApp(showOnboarding: false),
      ),
    );

    // Let the first frame settle.
    await tester.pump();

    // Verify the app renders its title in the swipe screen app bar.
    expect(find.text('Pickish'), findsOneWidget);
  });
}
