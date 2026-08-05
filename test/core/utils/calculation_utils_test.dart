import 'package:flutter_test/flutter_test.dart';
import 'package:lastboss/core/utils/calculation_utils.dart';

void main() {
  group('CalculationUtils', () {
    test('คำนวณราคา CO₂ และคะแนนจากน้ำหนัก', () {
      expect(
        CalculationUtils.calculateEstimatedPrice(
          weightKg: 2.5,
          pricePerKg: 8.5,
        ),
        21.25,
      );
      expect(
        CalculationUtils.calculateCo2Saved(weightKg: 2.5, co2Factor: 1.5),
        3.75,
      );
      expect(CalculationUtils.calculatePoints(3.75), 37);
    });

    test('วัสดุที่ไม่มีมูลค่ายังมีผลลัพธ์เป็นศูนย์', () {
      expect(
        CalculationUtils.calculateEstimatedPrice(weightKg: 0, pricePerKg: 0),
        0,
      );
      expect(CalculationUtils.calculatePoints(0), 0);
    });
  });
}
