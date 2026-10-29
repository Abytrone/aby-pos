// Enums shared by the drift tables and the UI. Stored by name, so never
// rename a value without a migration.

enum CategoryTone { midnight, lime, blue, coral }

enum SaleStatus { completed, voided }

/// What kind of payment a method is (the shop names its own methods, see
/// PayMethod). `exchange` is the value of items returned in an exchange.
enum PaymentMethod {
  cash('Cash'),
  momo('Mobile money'),
  credit('Credit (book)'),
  card('Card'),
  bank('Bank transfer'),
  cheque('Cheque'),
  exchange('Exchange'),
  other('Other'),
  wallet('Wallet'),
  voucher('Gift voucher');

  const PaymentMethod(this.label);
  final String label;
}

/// Why stock moved. `restock` is a delivery received; `count` is the
/// correction a stock count posts.
/// `production` is stock made here (or the ingredients it used).
enum StockReason { sale, restock, waste, adjustment, count, returned, production }

/// A purchase order: sent and waiting, partly delivered, all delivered, or
/// called off.
enum PurchaseOrderStatus { open, partial, received, cancelled }

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

/// How a product is counted at the till. By weight or volume, the line's
/// quantity is grams or millilitres and the price is per kg or litre.
enum SellBy { each, kg, litre }

enum DiscountKind { percent, amount }

/// What an automatic promotion does.
enum PromotionKind { percentOff, buyGet, bundle, quantityBreak, spend }

/// Where a saved discount can be used.
enum DiscountScope { line, order, any }

/// Lists of reasons the owner manages, one per purpose.
enum ReasonKind { discount, voidSale, refund, noSale, payIn, payOut }

/// Takeaway, eat-in or delivery, when the shop switches order types on.
enum OrderType { takeaway, eatIn, delivery }

/// Where an order with a queue number is (SEL-11).
enum OrderStatus { fresh, preparing, ready, collected }

enum ParkedOrderStatus { parked, resumed, discarded }

/// Drawer events that are not sales: opening it without one, cash put in
/// (change from the bank) or taken out (paying for ice), and cash moved to
/// the safe.
enum CashEventKind { noSale, payIn, payOut, safeDrop }

/// The safe: cash dropped in from drawers, taken to the bank, or corrected.
enum SafeEntryKind { drop, deposit, adjustment }

enum ShiftStatus { open, closed }

/// A customer's two accounts: what they owe (credit book) and what the shop
/// holds for them (wallet / store credit).
/// The loyalty account counts stamps or points, not money.
enum CustomerAccount { credit, wallet, loyalty }

/// Entries in a customer account. On the credit account a positive amount
/// is owed; on the wallet a positive amount is held for the customer.
enum CustomerEntryKind {
  creditSale,
  repayment,
  writeOff,
  creditRefund,
  topUp,
  changeKept,
  walletSpend,
  walletRefund,
  adjustment,
  loyaltyEarn,
  loyaltyRedeem,
  loyaltyExpire,

  /// Undoes an entry of a voided sale.
  voidReversal,
}

/// Movements on a gift voucher: what it was sold for, spending, money put
/// back by a void, and what was left when it expired.
enum VoucherEntryKind { issued, spent, voidReturn, expired }

/// Where the money for an expense or an owner drawing came from.
enum MoneySource { drawer, momo, bank, ownerPocket }

/// The owner taking money out for themselves, or putting their own in.
enum OwnerMoneyKind { drawing, capital }
