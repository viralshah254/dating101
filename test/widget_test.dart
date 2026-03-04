// Basic Flutter widget test for Shubhmilan.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:saathi/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: ShubhmilanApp(),
      ),
    );
    expect(find.text('Shubhmilan'), findsOneWidget);
  });
}
