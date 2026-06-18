import 'package:flutter_test/flutter_test.dart';
import 'package:txeneza_app/app.dart';

void main() {
  testWidgets('App theme and token verification smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const App());

    // Verify that the title or key screen elements exist.
    expect(find.text('Txeneza'), findsOneWidget);
    expect(find.text('Design Tokens'), findsOneWidget);
  });
}
