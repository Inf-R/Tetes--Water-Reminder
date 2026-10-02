import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('AquaTrack app smoke test', (WidgetTester tester) async {
    // Smoke test — verifies the app can be instantiated
    // Full provider-dependent tests will be added in Phase 2
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Center(child: Text('AquaTrack')),
          ),
        ),
      ),
    );

    expect(find.text('AquaTrack'), findsOneWidget);
  });
}
