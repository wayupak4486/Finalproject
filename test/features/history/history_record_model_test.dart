import 'package:flutter_test/flutter_test.dart';
import 'package:lastboss/features/history/data/models/history_record_model.dart';

void main() {
  test('HistoryRecordModel แปลงข้อมูลสำหรับ SQLite แล้วอ่านกลับได้', () {
    final createdAt = DateTime.utc(2026, 8, 5, 9, 30);
    final record = HistoryRecordModel(
      id: 7,
      imagePath: '/tmp/scan.jpg',
      material: 'ขวดพลาสติก PET',
      category: 'พลาสติก',
      confidence: 92.5,
      weight: 1.25,
      pricePerKg: 8.5,
      estimatedPrice: 10.625,
      co2Saved: 1.875,
      pointsEarned: 18,
      note: 'ล้างแล้ว',
      createdAt: createdAt,
    );

    final map = record.toMap()..['id'] = record.id;
    final restored = HistoryRecordModel.fromMap(map);

    expect(restored.id, 7);
    expect(restored.material, record.material);
    expect(restored.estimatedPrice, record.estimatedPrice);
    expect(restored.createdAt, createdAt);
  });
}
