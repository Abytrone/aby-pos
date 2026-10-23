// Enums shared by the drift tables and the UI. Stored by name, so never
// rename a value without a migration.

enum CategoryTone { midnight, lime, blue, coral }

enum SaleStatus { completed, voided }

enum PaymentMethod {
  cash('Cash'),
  momo('Mobile money'),
  credit('Credit (book)');

  const PaymentMethod(this.label);
  final String label;
}

/// Why stock moved. `restock` is a delivery received; `count` is the
/// correction a stock count posts.
enum StockReason { sale, restock, waste, adjustment, count }

/// Base units for stock items. Quantities are whole numbers of these.
enum StockUnit { piece, g, ml }

/// What went wrong with wasted stock.
enum WasteReason { melted, powerCut, expired, damaged, staffMeal, sample, other }

enum StockCountStatus { open, posted, cancelled }

/// Entries in what the shop owes a supplier: deliveries add, payments take away.
enum SupplierEntryKind { purchase, payment, adjustment }

enum SupplierPaymentMethod { cash, momo, bank, other }

enum OutboxOperation { insert, update, delete }

/// Settings either apply to the whole shop (and sync) or to this device only.
enum SettingScope { shop, device }
