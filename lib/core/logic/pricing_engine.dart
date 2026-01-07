import 'package:decimal/decimal.dart';

class PriceResolutionEngine {
  /// Resolves the final selling price.
  /// Future-proofed for:
  /// - Wholesale tiers
  /// - Customer-specific pricing
  /// - Time-based promotions
  static double resolvePrice({
    required double basePrice,
    // Add context parameters later: customerGroup, date, qty
  }) {
    // For now, simple base price.
    // In Phase 2: Check for active promotions here.
    return basePrice;
  }
}

class TaxEngine {
  // Simple VAT logic for now. 
  // Sri Lanka has VAT, SSCL etc. We structure this to be additive.
  
  static double calculateTax({
    required double price, 
    required double taxRate, // e.g., 0.18 for 18%
    required bool isPriceInclusive,
  }) {
    if (isPriceInclusive) {
      // Price = Base + Tax
      // Base = Price / (1 + Rate)
      // Tax = Price - Base
      final base = price / (1 + taxRate);
      return price - base;
    } else {
      return price * taxRate;
    }
  }
}
