import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lastboss/app/app.dart';

void main() {
  testWidgets('App shows home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: RecycleAiApp()));

    expect(find.text('Recycle AI'), findsWidgets);
    expect(find.text('Scan Material'), findsOneWidget);
    expect(find.byIcon(Icons.recycling), findsOneWidget);
  });
}
