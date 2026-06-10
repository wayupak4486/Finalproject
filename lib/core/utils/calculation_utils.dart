import '../constants/app_constants.dart';

class CalculationUtils {
  const CalculationUtils._();

  static double calculateEstimatedPrice({
    required double weightKg,
    required double pricePerKg,
  }) {
    return weightKg * pricePerKg;
  }

  static double calculateCo2Saved({
    required double weightKg,
    required double co2Factor,
  }) {
    return weightKg * co2Factor;
  }

  static int calculatePoints(double co2Saved) {
    return (co2Saved * AppConstants.pointsPerKgCo2e).floor();
  }
}
