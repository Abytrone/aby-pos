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

enum StockReason { sale, restock, waste, adjustment }

enum OutboxOperation { insert, update, delete }

enum StaffRole {
  owner('Owner'),
  cashier('Cashier');

  const StaffRole(this.label);
  final String label;
}
