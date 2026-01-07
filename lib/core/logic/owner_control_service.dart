import '../database/app_database.dart';
import 'package:drift/drift.dart';

class OwnerControlService {
  final AppDatabase _db;

  OwnerControlService(this._db);

  /// Generates the "Pulse" Report - A collection of red flags.
  Future<List<Alert>> generateAlerts() async {
    List<Alert> alerts = [];

    // 1. Fraud: Price Hikes in GRN
    // Query PurchaseGrnItems where isPriceIncrease = true
    final hikedItems = await (_db.select(_db.purchaseGrnItems)
      ..where((t) => t.isPriceIncrease.equals(true)))
      .get();
      
    if (hikedItems.isNotEmpty) {
      alerts.add(Alert(
        type: AlertType.PRICE_HIKE,
        message: "${hikedItems.length} items have increased in cost recently.",
        severity: Severity.HIGH
      ));
    }
    
    // 2. Dead Stock
    // Find batches older than 90 days with Qty > 0
    final ninetyDaysAgo = DateTime.now().subtract(const Duration(days: 90));
    final deadBatches = await (_db.select(_db.stockBatches)
      ..where((t) => t.receivedAt.isSmallerThanValue(ninetyDaysAgo) & t.quantityOnHand.isBiggerThanValue(0)))
      .get();
      
    if (deadBatches.isNotEmpty) {
      alerts.add(Alert(
        type: AlertType.DEAD_STOCK,
        message: "${deadBatches.length} batches are older than 90 days.",
        severity: Severity.MEDIUM
      ));
    }

    // 3. Low Margin Sales (Last 24h)
    // Find items sold with < 15% margin
    final oneDayAgo = DateTime.now().subtract(const Duration(hours: 24));
    
    final recentItems = await (_db.select(_db.saleItems).join([
      innerJoin(_db.sales, _db.sales.id.equalsExp(_db.saleItems.saleId))
    ])
      ..where(_db.sales.saleDate.isBiggerThanValue(oneDayAgo))
    ).get();

    int lowMarginCount = 0;
    for (final row in recentItems) {
      final item = row.readTable(_db.saleItems);
      if (item.unitPrice > 0 && item.costPrice > 0) {
        final margin = (item.unitPrice - item.costPrice) / item.unitPrice;
        if (margin < 0.15) lowMarginCount++;
      }
    }

    if (lowMarginCount > 0) {
      alerts.add(Alert(
        type: AlertType.LOW_MARGIN,
        message: "$lowMarginCount items sold with < 15% margin today.",
        severity: Severity.HIGH
      ));
    }
    
    // 4. Refund/Void Abuse (Last 24h)
    final refundLogs = await (_db.select(_db.auditLogs)
      ..where((t) => t.action.isIn(['REFUND', 'VOID_SALE']) & t.timestamp.isBiggerThanValue(oneDayAgo))
    ).get();

    if (refundLogs.length > 5) {
      alerts.add(Alert(
        type: AlertType.SUSPICIOUS_ACTIVITY,
        message: "High refund/void volume detected (${refundLogs.length} events).",
        severity: Severity.CRITICAL
      ));
    }
    
    return alerts;
  }
}

class Alert {
  final AlertType type;
  final String message;
  final Severity severity;

  Alert({required this.type, required this.message, required this.severity});
}

enum AlertType { PRICE_HIKE, DEAD_STOCK, LOW_MARGIN, SUSPICIOUS_ACTIVITY }
enum Severity { LOW, MEDIUM, HIGH, CRITICAL }
