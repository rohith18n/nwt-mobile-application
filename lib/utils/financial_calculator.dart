import 'dart:math';

/// A utility class for financial calculations used across the app
class FinancialCalculator {
  /// Calculates the future value of an investment
  /// 
  /// Parameters:
  /// - [presentValue]: The initial investment amount
  /// - [interestRate]: Annual interest rate as a percentage (e.g., 10 for 10%)
  /// - [years]: Number of years for the investment
  /// 
  /// Returns the future value based on the formula FV = PV * (1 + i)^n
  static double calculateFutureValue({
    required double presentValue,
    required double interestRate,
    required double years,
  }) {
    // Convert percentage to decimal
    final rate = interestRate / 100;
    
    // Apply the formula: FV = PV * (1 + i)^n
    return presentValue * pow(1 + rate, years);
  }

  /// Calculates the potential savings between direct and regular mutual fund plans
  /// 
  /// Parameters:
  /// - [presentValue]: The initial investment amount
  /// - [directPlanRate]: Annual return rate for direct plan as a percentage
  /// - [regularPlanRate]: Annual return rate for regular plan as a percentage
  /// - [years]: Number of years for the investment
  /// 
  /// Returns a map containing directPlanValue, regularPlanValue, and potentialSavings
  static Map<String, double> calculateMutualFundSavings({
    required double presentValue,
    required double directPlanRate,
    required double regularPlanRate,
    required double years,
  }) {
    final directPlanValue = calculateFutureValue(
      presentValue: presentValue,
      interestRate: directPlanRate,
      years: years,
    );
    
    final regularPlanValue = calculateFutureValue(
      presentValue: presentValue,
      interestRate: regularPlanRate,
      years: years,
    );
    
    final potentialSavings = directPlanValue - regularPlanValue;
    
    return {
      'directPlanValue': directPlanValue,
      'regularPlanValue': regularPlanValue,
      'potentialSavings': potentialSavings,
    };
  }
}
