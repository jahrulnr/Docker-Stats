// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:docker_stats_app/main.dart';
import 'package:docker_stats_app/injection_container.dart' as di;
import 'package:docker_stats_app/presentation/pages/containers_page.dart';

void main() {
  setUpAll(() async {
    await di.init();
  });

  testWidgets('App loads and shows containers page', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Wait for the app to initialize and load data
    await tester.pumpAndSettle();

    // Verify that we can find the containers page (it should show either containers or loading/error)
    expect(find.byType(ContainersPage), findsOneWidget);
  });
}
