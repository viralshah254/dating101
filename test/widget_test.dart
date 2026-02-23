// Basic Flutter widget test for DesiLink.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:desilink/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: DesiLinkApp(),
      ),
    );
    expect(find.text('DesiLink'), findsOneWidget);
  });
}
