// Basic Flutter widget test for Shubhmilan.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/app_test_harness.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    final app = await buildTestApp();
    await tester.pumpWidget(app);
    await tester.pump();
    expect(find.byType(ProviderScope), findsOneWidget);
  });
}
