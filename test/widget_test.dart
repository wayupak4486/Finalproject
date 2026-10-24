import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lastboss/features/history/data/models/history_record_model.dart';
import 'package:lastboss/features/home/presentation/screens/home_screen.dart';

void main() {
  testWidgets('หน้าแรกแสดงสถานะโหลดและข้อมูลว่าง', (tester) async {
    final records = Completer<List<HistoryRecordModel>>();

    await tester.pumpWidget(
      MaterialApp(home: HomeScreen(historyLoader: () async => records.future)),
    );

    expect(find.text('Scan Material'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -1000));
    await tester.pump();
    expect(
      find.byType(CircularProgressIndicator, skipOffstage: false),
      findsOneWidget,
    );
    records.complete([]);
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -1000));
    await tester.pumpAndSettle();
    expect(find.text('ยังไม่มีรายการ', skipOffstage: false), findsOneWidget);
  });

  testWidgets('หน้าแรกสรุปและแสดงรายการล่าสุดจากประวัติ', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: HomeScreen(historyLoader: _singleRecord)),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -1000));
    await tester.pumpAndSettle();
    expect(find.text('ขวดพลาสติก PET', skipOffstage: false), findsOneWidget);
    expect(find.text('17.00 บาท', skipOffstage: false), findsWidgets);
    expect(find.text('30', skipOffstage: false), findsOneWidget);
  });
}

Future<List<HistoryRecordModel>> _singleRecord() async => [
  HistoryRecordModel(
    id: 1,
    imagePath: '/missing/image.jpg',
    material: 'ขวดพลาสติก PET',
    category: 'พลาสติก',
    confidence: 95,
    weight: 2,
    pricePerKg: 8.5,
    estimatedPrice: 17,
    co2Saved: 3,
    co2FactorPerKg: 1.5,
    pointsEarned: 30,
    note: null,
    createdAt: DateTime(2026, 8, 5),
  ),
];
