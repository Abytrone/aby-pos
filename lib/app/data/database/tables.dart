import 'package:drift/drift.dart';

import '../../models/audit.dart';
import '../../models/enums.dart';
import 'converters.dart';

/// Columns every syncable table carries. IDs are client-generated UUID v7.
/// Rows are never hard-deleted; set [deletedAt] instead.
mixin SyncColumns on Table {
  TextColumn get id => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  /// When the server last confirmed this row. Null means not yet synced.
  DateTimeColumn get syncedAt => dateTime().nullable()();
  TextColumn get deviceId => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('CategoryRow')
class Categories extends Table with SyncColumns {
  TextColumn get name => text()();
  TextColumn get tone => textEnum<CategoryTone>()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  /// A sub-category's parent (two levels at most). v5.
  TextColumn get parentId => text().nullable()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();

  /// The picture a product without a photo shows (a Lucide category icon
  /// name, e.g. "ice-cream-cone"). Null: worked out from the name. v18.
  TextColumn get icon => text().nullable()();
}

@DataClassName('ProductRow')
class Products extends Table with SyncColumns {
  TextColumn get categoryId => text().references(Categories, #id)();
  TextColumn get name => text()();

  /// Short line on the till tile, e.g. "500 ml".
  TextColumn get detail => text().nullable()();
  TextColumn get description => text().nullable()();

  /// Shown on the till and sellable.
  BoolColumn get active => boolean().withDefault(const Constant(true))();

  /// Archived products are kept for history but hidden everywhere else.
  DateTimeColumn get archivedAt => dateTime().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  /// Counted, or weighed / measured (price per kg or litre). v6.
  TextColumn get sellBy => textEnum<SellBy>().withDefault(const Constant('each'))();

  /// The price is typed at the till ("Miscellaneous"), between the
  /// optional limits (pesewas). The variant's price is the suggestion. v6.
  BoolColumn get openPrice => boolean().withDefault(const Constant(false))();
  IntColumn get minPrice => integer().nullable()();
  IntColumn get maxPrice => integer().nullable()();

  /// Position on the till's Quick tab; null when not on it. v6.
  IntColumn get quickOrder => integer().nullable()();

  /// Pesewas of commission per one sold, when the shop pays commission per
  /// product (STF-07). v15.
  IntColumn get commission => integer().nullable()();
}

/// What is actually sold and priced. Every product has at least one; a
/// product with one unnamed variant is a "simple" product.
@DataClassName('VariantRow')
class ProductVariants extends Table with SyncColumns {
  TextColumn get productId => text().references(Products, #id)();

  /// "Single scoop", "500 ml". Null for a simple product's only variant.
  TextColumn get name => text().nullable()();

  /// Pesewas.
  IntColumn get price => integer()();

  /// Pesewas. Used when the variant has no recipe to work its cost out.
  IntColumn get manualCost => integer().nullable()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

/// A set of extras or choices on a product: "Toppings", "Sugar level".
@DataClassName('OptionGroupRow')
class OptionGroups extends Table with SyncColumns {
  TextColumn get name => text()();

  /// How many must be picked (0 = optional).
  IntColumn get minSelect => integer().withDefault(const Constant(0))();

  /// How many may be picked; null = no limit.
  IntColumn get maxSelect => integer().nullable()();

  /// The same option may be picked more than once (double sprinkles).
  BoolColumn get allowRepeat => boolean().withDefault(const Constant(false))();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

@DataClassName('OptionRow')
class OptionItems extends Table with SyncColumns {
  TextColumn get groupId => text().references(OptionGroups, #id)();
  TextColumn get name => text()();

  /// Pesewas added to the price (may be 0).
  IntColumn get priceDelta => integer().withDefault(const Constant(0))();

  /// Picked already when the picker opens.
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  /// A combo part: this option is that product variant, and uses up its
  /// recipe when the option has none of its own. v11.
  TextColumn get variantId => text().nullable()();
}

@DataClassName('ProductOptionGroupRow')
class ProductOptionGroups extends Table with SyncColumns {
  TextColumn get productId => text().references(Products, #id)();
  TextColumn get groupId => text().references(OptionGroups, #id)();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

/// What the shop buys and keeps: cones (pieces), vanilla (ml), sprinkles (g).
@DataClassName('StockItemRow')
class StockItems extends Table with SyncColumns {
  TextColumn get name => text()();
  TextColumn get unit => textEnum<StockUnit>()();

  /// Thousandths of a pesewa per base unit (piece, g or ml), so one cone
  /// from a GH₵ 33 pack of 24 (137.5 pesewas) is exact: 137500.
  IntColumn get costMilli => integer().withDefault(const Constant(0))();

  /// Base units. Below this, the item shows as low.
  IntColumn get reorderPoint => integer().nullable()();
  IntColumn get reorderQty => integer().nullable()();
  TextColumn get supplierId => text().nullable()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();

  /// Batch numbers and expiry dates are asked for when receiving. v14.
  BoolColumn get tracksExpiry => boolean().withDefault(const Constant(false))();

  /// Made here: base units one batch of its recipe makes (the recipe is the
  /// recipe lines with [RecipeItems.madeItemId] = this item). v14.
  IntColumn get batchYield => integer().nullable()();
}

/// What a variant (or an option) uses up each time it is sold.
@DataClassName('RecipeItemRow')
class RecipeItems extends Table with SyncColumns {
  TextColumn get variantId => text().nullable().references(ProductVariants, #id)();
  TextColumn get optionId => text().nullable().references(OptionItems, #id)();

  /// An ingredient of a stock item made here (production). v14.
  TextColumn get madeItemId => text().nullable()();
  TextColumn get stockItemId => text().references(StockItems, #id)();

  /// Base units.
  IntColumn get quantity => integer()();
}

@DataClassName('TaxRateRow')
class TaxRates extends Table with SyncColumns {
  TextColumn get name => text()();

  /// Basis points: 1500 = 15%.
  IntColumn get rateBp => integer()();

  /// Charged on the price plus the non-compound taxes (as VAT is on top of
  /// NHIL and GETFund).
  BoolColumn get compound => boolean().withDefault(const Constant(false))();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

@DataClassName('ProductTaxRow')
class ProductTaxes extends Table with SyncColumns {
  TextColumn get productId => text().references(Products, #id)();
  TextColumn get taxRateId => text().references(TaxRates, #id)();
}

@DataClassName('BarcodeRow')
class Barcodes extends Table with SyncColumns {
  TextColumn get code => text()();
  TextColumn get variantId => text().references(ProductVariants, #id)();
}

/// Product photos, small, kept out of sync payloads (like staff photos).
// TODO(sync): upload as files once the API has storage for them.
@DataClassName('ProductPhotoRow')
class ProductPhotos extends Table {
  TextColumn get productId => text().references(Products, #id)();
  BlobColumn get image => blob()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {productId};
}

/// A price that takes effect on a date.
@DataClassName('PriceChangeRow')
class PriceChanges extends Table with SyncColumns {
  TextColumn get variantId => text().references(ProductVariants, #id)();

  /// Pesewas.
  IntColumn get newPrice => integer()();

  /// Start of the business day it applies from.
  DateTimeColumn get effectiveOn => dateTime()();
  DateTimeColumn get appliedAt => dateTime().nullable()();
  DateTimeColumn get cancelledAt => dateTime().nullable()();
  TextColumn get createdByName => text()();
}

@DataClassName('SupplierRow')
class Suppliers extends Table with SyncColumns {
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get notes => text().nullable()();

  /// Days they give us to pay; null = pay on delivery.
  IntColumn get paymentTermsDays => integer().nullable()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
}

/// What the shop owes each supplier, as a ledger: the balance is the sum.
@DataClassName('SupplierEntryRow')
class SupplierLedger extends Table with SyncColumns {
  TextColumn get supplierId => text().references(Suppliers, #id)();
  TextColumn get kind => textEnum<SupplierEntryKind>()();

  /// Pesewas. Positive: we owe more (a delivery). Negative: we paid.
  IntColumn get amount => integer()();
  TextColumn get method => textEnum<SupplierPaymentMethod>().nullable()();
  TextColumn get receiptId => text().nullable()();
  TextColumn get reference => text().nullable()();
  TextColumn get note => text().nullable()();
  TextColumn get byName => text()();
}

/// A delivery received ("goods received note").
@DataClassName('StockReceiptRow')
class StockReceipts extends Table with SyncColumns {
  /// Per-device sequence, shown as "GRN-0001".
  IntColumn get number => integer()();
  TextColumn get supplierId => text().nullable().references(Suppliers, #id)();
  TextColumn get invoiceRef => text().nullable()();

  /// Pesewas.
  IntColumn get total => integer()();

  /// Pesewas paid on delivery (the rest is owed to the supplier).
  IntColumn get paidNow => integer().withDefault(const Constant(0))();
  TextColumn get note => text().nullable()();
  TextColumn get receivedById => text()();
  TextColumn get receivedByName => text()();

  /// The purchase order this delivery was received against. v14.
  TextColumn get purchaseOrderId => text().nullable()();
}

@DataClassName('StockReceiptLineRow')
class StockReceiptLines extends Table with SyncColumns {
  TextColumn get receiptId => text().references(StockReceipts, #id)();
  TextColumn get stockItemId => text().references(StockItems, #id)();

  /// Base units.
  IntColumn get quantity => integer()();

  /// Thousandths of a pesewa per base unit.
  IntColumn get unitCostMilli => integer()();

  /// Pesewas.
  IntColumn get lineTotal => integer()();
}

@DataClassName('StockCountRow')
class StockCounts extends Table with SyncColumns {
  TextColumn get status => textEnum<StockCountStatus>()();

  /// Counters do not see what the till expects.
  BoolColumn get blind => boolean().withDefault(const Constant(true))();
  TextColumn get note => text().nullable()();
  TextColumn get startedById => text()();
  TextColumn get startedByName => text()();
  DateTimeColumn get postedAt => dateTime().nullable()();
  TextColumn get postedById => text().nullable()();
  TextColumn get postedByName => text().nullable()();
}

@DataClassName('StockCountLineRow')
class StockCountLines extends Table with SyncColumns {
  TextColumn get countId => text().references(StockCounts, #id)();
  TextColumn get stockItemId => text().references(StockItems, #id)();

  /// On hand when this line was counted. Sales after that are on top.
  IntColumn get expected => integer()();
  IntColumn get counted => integer()();
  TextColumn get countedByName => text()();
}

@DataClassName('SaleRow')
class Sales extends Table with SyncColumns {
  /// Per-device sequence, shown as "#00142". Unique with [deviceId].
  IntColumn get number => integer()();
  TextColumn get status => textEnum<SaleStatus>()();

  /// Pesewas.
  IntColumn get subtotal => integer()();

  /// Pesewas.
  IntColumn get total => integer()();
  /// Who rang it up. Null for sales from before staff sign-in (schema v1).
  TextColumn get cashierId => text().nullable()();
  TextColumn get cashierName => text()();
  DateTimeColumn get voidedAt => dateTime().nullable()();

  /// Who voided (or, for a cashier, which owner approved it).
  TextColumn get voidedById => text().nullable()();
  TextColumn get voidedBy => text().nullable()();

  /// Pesewas of tax in the total. v5.
  IntColumn get taxTotal => integer().withDefault(const Constant(0))();

  /// Pesewas taken off: line discounts plus the order discount. [subtotal]
  /// is before discounts. v6.
  IntColumn get discountTotal => integer().withDefault(const Constant(0))();

  /// The whole-order discount as given (JSON: kind, value, reason, name). v6.
  TextColumn get orderDiscount => text().nullable()();
  TextColumn get note => text().nullable()();
  TextColumn get orderType => textEnum<OrderType>().nullable()();

  /// The customer the sale is for, when one was attached. v8.
  TextColumn get customerId => text().nullable()();

  /// Pesewas added (or taken off, when negative) by rounding a cash total.
  /// The payments add up to [total] plus this. v7.
  IntColumn get rounding => integer().withDefault(const Constant(0))();

  /// The queue number for the day ("A23" is 23), when the shop uses order
  /// numbers, and where the order is in prep. v13.
  IntColumn get orderNumber => integer().nullable()();
  TextColumn get orderStatus => textEnum<OrderStatus>().nullable()();
  DateTimeColumn get orderStatusAt => dateTime().nullable()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {deviceId, number},
      ];
}

@DataClassName('SaleLineRow')
class SaleLines extends Table with SyncColumns {
  TextColumn get saleId => text().references(Sales, #id)();
  TextColumn get productId => text().references(Products, #id)();
  TextColumn get variantId => text().nullable().references(ProductVariants, #id)();

  /// Names as sold, so the sale reads the same after the menu changes.
  TextColumn get productName => text()();
  TextColumn get variantName => text().nullable()();
  IntColumn get quantity => integer()();

  /// Pesewas for one unit, add-ons included.
  IntColumn get unitPrice => integer()();

  /// Pesewas.
  IntColumn get lineTotal => integer()();
  /// The options picked, as sold (JSON). Named addons for history.
  TextColumn get addons =>
      text().map(const SoldAddonsConverter()).withDefault(const Constant('[]'))();

  /// Pesewas: what the stock used cost (recipes), for profit. v5.
  IntColumn get costTotal => integer().withDefault(const Constant(0))();

  /// Pesewas of tax in (or on top of) the line. v5.
  IntColumn get taxTotal => integer().withDefault(const Constant(0))();

  /// Counted, or weighed (then [quantity] is grams or ml and [unitPrice] is
  /// per kg or litre). v6.
  TextColumn get sellBy => textEnum<SellBy>().withDefault(const Constant('each'))();

  /// The menu price for one, when the price was overridden or typed in. v6.
  IntColumn get listPrice => integer().nullable()();

  /// Who overrode the price (the person whose permission was used). v6.
  TextColumn get priceOverriddenBy => text().nullable()();

  /// Pesewas off this line, and its share of the order discount. [lineTotal]
  /// is before both. v6.
  IntColumn get discount => integer().withDefault(const Constant(0))();
  IntColumn get orderDiscountShare => integer().withDefault(const Constant(0))();

  /// Pesewas of [discount] that came from automatic promotions, and their
  /// names. v11.
  IntColumn get promotion => integer().withDefault(const Constant(0))();
  TextColumn get promotionName => text().nullable()();

  /// The line discount as given (JSON: kind, value, reason, name). v6.
  TextColumn get discountDetail => text().nullable()();
  TextColumn get note => text().nullable()();

  /// Stock this line used, {stockItemId: base units} (JSON), so a refund
  /// puts back exactly that. Null before v7.
  TextColumn get stockUsed => text().nullable()();
}

/// Tax on a sale, per rate, for the tax report.
@DataClassName('SaleTaxRow')
class SaleTaxes extends Table with SyncColumns {
  TextColumn get saleId => text().references(Sales, #id)();
  TextColumn get taxRateId => text()();
  TextColumn get name => text()();
  IntColumn get rateBp => integer()();

  /// Pesewas.
  IntColumn get amount => integer()();
}

@DataClassName('PaymentRow')
class Payments extends Table with SyncColumns {
  TextColumn get saleId => text().references(Sales, #id)();
  TextColumn get method => textEnum<PaymentMethod>()();

  /// Pesewas applied to the sale.
  IntColumn get amount => integer()();

  /// Cash only: pesewas handed over and change given back.
  IntColumn get tendered => integer().nullable()();
  IntColumn get changeGiven => integer().nullable()();
  /// The transaction reference (MoMo, bank, cheque). Named for v1.
  TextColumn get momoReference => text().nullable()();

  /// Credit only: customer name or phone.
  TextColumn get customer => text().nullable()();

  /// The shop's payment method and its name as sold ("MTN MoMo"). Null
  /// before v7: [method] says what it was. v7.
  TextColumn get methodId => text().nullable()();
  TextColumn get methodName => text().nullable()();
}

/// People who buy: looked up by phone, with a credit account and a wallet.
@DataClassName('CustomerRow')
class Customers extends Table with SyncColumns {
  TextColumn get name => text()();

  /// +233XXXXXXXXX. Unique among active customers.
  TextColumn get phone => text().nullable()();
  TextColumn get phone2 => text().nullable()();

  /// As people give directions ("near the mosque, Lamashegu").
  TextColumn get location => text().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get birthday => dateTime().nullable()();

  /// JSON list of tags ("Wholesale", "Staff").
  TextColumn get tags => text().withDefault(const Constant('[]'))();

  /// Pesewas they may owe at most; null for no limit.
  IntColumn get creditLimit => integer().nullable()();

  /// Days to pay for a credit sale; null for no due date.
  IntColumn get dueDays => integer().nullable()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
}

/// Both customer accounts as one append-only ledger. A balance is the sum
/// of an account's entries, never a stored number.
@DataClassName('CustomerEntryRow')
class CustomerLedger extends Table with SyncColumns {
  TextColumn get customerId => text().references(Customers, #id)();
  TextColumn get account => textEnum<CustomerAccount>()();
  TextColumn get kind => textEnum<CustomerEntryKind>()();

  /// Pesewas: on credit, + owed / − paid; on the wallet, + held / − used.
  IntColumn get amount => integer()();
  TextColumn get saleId => text().nullable()();
  TextColumn get refundId => text().nullable()();

  /// A repayment for one sale; null pays the oldest debts first.
  TextColumn get appliesToSaleId => text().nullable()();

  /// For a credit sale, when it should be paid.
  DateTimeColumn get dueOn => dateTime().nullable()();

  /// How money came in or went out (repayments, top-ups), so cash ones
  /// count in the drawer.
  TextColumn get method => textEnum<PaymentMethod>().nullable()();
  TextColumn get methodName => text().nullable()();
  TextColumn get reference => text().nullable()();
  TextColumn get note => text().nullable()();
  TextColumn get byName => text()();
  TextColumn get approverName => text().nullable()();
}

/// The ways a shop takes payment, which the owner can rename and switch on
/// or off. Built-in rows have IDs derived from [builtIn].
@DataClassName('PayMethodRow')
class PayMethods extends Table with SyncColumns {
  TextColumn get name => text()();
  TextColumn get kind => textEnum<PaymentMethod>()();

  /// Key of a built-in method ("cash", "mtn"...), null for the owner's own.
  TextColumn get builtIn => text().nullable()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();

  /// A transaction reference must be entered (and may not be reused).
  BoolColumn get needsReference => boolean().withDefault(const Constant(false))();

  /// The last 4 characters of the reference are enough.
  BoolColumn get shortReference => boolean().withDefault(const Constant(false))();

  /// The shop's number or merchant ID, shown large to the customer.
  TextColumn get merchantNumber => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

/// Money and items given back. A refund is its own record, linked to the
/// sale (unless there was no receipt); the sale is never changed.
@DataClassName('RefundRow')
class Refunds extends Table with SyncColumns {
  /// Per-device sequence, shown as "R-0001". Unique with [deviceId].
  IntColumn get number => integer()();
  TextColumn get saleId => text().nullable().references(Sales, #id)();
  IntColumn get saleNumber => integer().nullable()();

  /// Pesewas.
  IntColumn get total => integer()();
  TextColumn get reason => text()();
  TextColumn get note => text().nullable()();
  BoolColumn get withoutReceipt => boolean().withDefault(const Constant(false))();

  /// Part of an exchange: the value went towards [exchangeSaleId].
  TextColumn get exchangeSaleId => text().nullable()();
  TextColumn get staffId => text()();
  TextColumn get staffName => text()();
  TextColumn get approverName => text().nullable()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {deviceId, number},
      ];
}

@DataClassName('RefundLineRow')
class RefundLines extends Table with SyncColumns {
  TextColumn get refundId => text().references(Refunds, #id)();
  TextColumn get saleLineId => text().nullable()();
  TextColumn get productId => text().nullable()();
  TextColumn get variantId => text().nullable()();
  TextColumn get productName => text()();
  TextColumn get variantName => text().nullable()();

  /// How many (grams or ml when weighed).
  IntColumn get quantity => integer()();
  TextColumn get sellBy => textEnum<SellBy>().withDefault(const Constant('each'))();

  /// Pesewas given back for this line.
  IntColumn get amount => integer()();

  /// Put back into stock; false for damaged items.
  BoolColumn get restocked => boolean()();
}

/// How a refund was paid out (or, for an exchange, put towards the new sale).
@DataClassName('RefundPaymentRow')
class RefundPayments extends Table with SyncColumns {
  TextColumn get refundId => text().references(Refunds, #id)();
  TextColumn get method => textEnum<PaymentMethod>()();
  TextColumn get methodId => text().nullable()();
  TextColumn get methodName => text()();

  /// Pesewas.
  IntColumn get amount => integer()();
  TextColumn get reference => text().nullable()();
}

/// The drawer opened without a sale, and why.
@DataClassName('CashEventRow')
class CashEvents extends Table with SyncColumns {
  TextColumn get kind => textEnum<CashEventKind>()();

  /// Pesewas in (+) or out (−); 0 for a no-sale.
  IntColumn get amount => integer().withDefault(const Constant(0))();
  TextColumn get reason => text()();
  TextColumn get staffId => text()();
  TextColumn get staffName => text()();
  TextColumn get approverName => text().nullable()();

  /// More detail ("Bought ice from Mr Issah"). v9.
  TextColumn get note => text().nullable()();
}

/// Photos of receipts and bank slips (pay-outs, deposits). Kept apart so
/// they stay out of sync payloads, like staff photos.
// TODO(sync): upload receipt photos as files.
@DataClassName('ReceiptPhotoRow')
class ReceiptPhotos extends Table {
  /// The cash event or safe entry the photo belongs to.
  TextColumn get ownerId => text()();
  BlobColumn get image => blob()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {ownerId};
}

/// A drawer's shift: who opened it with what float. The close (Z report)
/// is a DayCloses row that points back here.
@DataClassName('ShiftRow')
class Shifts extends Table with SyncColumns {
  TextColumn get status => textEnum<ShiftStatus>()();
  TextColumn get openedById => text()();
  TextColumn get openedByName => text()();

  /// Pesewas, and the notes and coins counted (JSON {"20000": 2, ...}).
  IntColumn get openingFloat => integer()();
  TextColumn get floatCount => text().nullable()();
  TextColumn get closeId => text().nullable()();
}

/// The safe: one ledger for the shop. Drops are + (in from a drawer),
/// deposits are − (to the bank). The balance is the sum.
@DataClassName('SafeEntryRow')
class SafeEntries extends Table with SyncColumns {
  TextColumn get kind => textEnum<SafeEntryKind>()();
  IntColumn get amount => integer()();
  TextColumn get bank => text().nullable()();
  TextColumn get reference => text().nullable()();
  TextColumn get note => text().nullable()();
  TextColumn get byName => text()();
}

/// The owner ticking MoMo payments off against their MoMo statement.
@DataClassName('MomoCheckRow')
class MomoChecks extends Table with SyncColumns {
  /// 'sale' (a payments row) or 'customer' (a customer_ledger row).
  TextColumn get source => text()();
  TextColumn get itemId => text()();
  BoolColumn get matched => boolean()();
  TextColumn get byName => text()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {source, itemId},
      ];
}

/// What expenses are for: rent, ECG, fuel... The owner edits the list.
@DataClassName('ExpenseCategoryRow')
class ExpenseCategories extends Table with SyncColumns {
  TextColumn get name => text()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

/// Money spent running the shop. Paid from the drawer, it is also a
/// pay-out ([cashEventId]) so the drawer count follows.
@DataClassName('ExpenseRow')
class Expenses extends Table with SyncColumns {
  /// The day it is for (start of the day).
  DateTimeColumn get day => dateTime()();

  /// Pesewas.
  IntColumn get amount => integer()();
  TextColumn get categoryId => text().references(ExpenseCategories, #id)();
  TextColumn get paidFrom => textEnum<MoneySource>()();
  TextColumn get supplierId => text().nullable()();
  TextColumn get note => text().nullable()();
  TextColumn get byName => text()();
  TextColumn get cashEventId => text().nullable()();
  TextColumn get recurringId => text().nullable()();
}

/// "Rent GH₵ 800 on the 1st": a reminder each month to confirm it.
@DataClassName('RecurringExpenseRow')
class RecurringExpenses extends Table with SyncColumns {
  TextColumn get name => text()();
  TextColumn get categoryId => text().references(ExpenseCategories, #id)();
  IntColumn get amount => integer()();

  /// 1 to 28.
  IntColumn get dayOfMonth => integer()();
  TextColumn get paidFrom => textEnum<MoneySource>()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();

  /// The last month confirmed or skipped, as "2026-10".
  TextColumn get doneUpTo => text().nullable()();
}

/// The owner's own money: drawings (taken home) and capital (put in). Kept
/// apart from expenses so profit is not understated.
@DataClassName('OwnerMoneyRow')
class OwnerMoney extends Table with SyncColumns {
  TextColumn get kind => textEnum<OwnerMoneyKind>()();
  IntColumn get amount => integer()();
  TextColumn get source => textEnum<MoneySource>()();
  TextColumn get note => text().nullable()();
  TextColumn get byName => text()();
  TextColumn get cashEventId => text().nullable()();
}

/// MoMo charges and e-levy taken off on a day, shown on their own line.
@DataClassName('MomoChargeRow')
class MomoCharges extends Table with SyncColumns {
  DateTimeColumn get day => dateTime()();
  IntColumn get amount => integer()();
  TextColumn get note => text().nullable()();
  TextColumn get byName => text()();
}

/// Discounts the owner saves for reuse: "Student 10%", "Staff meal GH₵ 5 off".
@DataClassName('DiscountRow')
class Discounts extends Table with SyncColumns {
  TextColumn get name => text()();
  TextColumn get kind => textEnum<DiscountKind>()();

  /// Whole percent, or pesewas.
  IntColumn get value => integer()();
  TextColumn get scope => textEnum<DiscountScope>()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

/// Reasons picked from a list: why a discount, a void, a refund, a no-sale.
/// Built-in rows have IDs derived from kind and name.
@DataClassName('ReasonRow')
class Reasons extends Table with SyncColumns {
  TextColumn get kind => textEnum<ReasonKind>()();
  TextColumn get name => text()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

/// Carts put aside ("Blue shirt", "Table 4") to finish later. The cart is
/// JSON (see CartSnapshot), resolved against the menu when resumed.
@DataClassName('ParkedOrderRow')
class ParkedOrders extends Table with SyncColumns {
  TextColumn get name => text()();
  TextColumn get status => textEnum<ParkedOrderStatus>()();
  TextColumn get cart => text()();

  /// Pesewas and item count when parked, for the tabs.
  IntColumn get total => integer()();
  IntColumn get itemCount => integer()();
  TextColumn get parkedById => text()();
  TextColumn get parkedByName => text()();
  DateTimeColumn get closedAt => dateTime().nullable()();
}

/// Append-only stock ledger. Stock on hand is the sum of [quantityChange]
/// for an item; never overwrite a level.
@DataClassName('StockMovementRow')
class StockMovements extends Table with SyncColumns {
  /// v1-v4 movements were per product; from v5 they are per stock item.
  TextColumn get productId => text().nullable().references(Products, #id)();
  TextColumn get variantId => text().nullable().references(ProductVariants, #id)();
  TextColumn get stockItemId => text().nullable().references(StockItems, #id)();

  /// Base units for stock items.
  IntColumn get quantityChange => integer()();
  TextColumn get reason => textEnum<StockReason>()();

  /// Waste reason, or other detail.
  TextColumn get subReason => text().nullable()();

  /// Cost per base unit at the time (thousandths of a pesewa).
  IntColumn get unitCostMilli => integer().nullable()();
  TextColumn get saleId => text().nullable().references(Sales, #id)();

  /// The delivery or stock count this came from.
  TextColumn get refId => text().nullable()();
  TextColumn get note => text().nullable()();
  TextColumn get byName => text().nullable()();
}

/// Named sets of permissions. Built-in roles have fixed IDs (BuiltInRole).
@DataClassName('RoleRow')
class Roles extends Table with SyncColumns {
  TextColumn get name => text()();

  /// BuiltInRole name, or null for roles the owner made.
  TextColumn get builtIn => text().nullable()();
  TextColumn get permissions =>
      text().map(const PermissionSetConverter()).withDefault(const Constant('[]'))();
  IntColumn get maxDiscountPercent => integer().withDefault(const Constant(0))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

/// People who can sign in. The PIN is stored only as a salted hash.
@DataClassName('StaffRow')
class StaffMembers extends Table with SyncColumns {
  @override
  String get tableName => 'staff';

  TextColumn get name => text()();
  TextColumn get roleId => text().references(Roles, #id)();

  /// See PinHasher for the format.
  TextColumn get pinHash => text()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();

  // Profile (v4). All optional.
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();

  /// Where they live, as people give directions ("behind the Lamashegu mosque").
  TextColumn get address => text().nullable()();
  TextColumn get emergencyName => text().nullable()();
  TextColumn get emergencyPhone => text().nullable()();

  /// Ghana Card number, e.g. GHA-123456789-0.
  TextColumn get idNumber => text().nullable()();
  DateTimeColumn get dateOfBirth => dateTime().nullable()();
  DateTimeColumn get startedOn => dateTime().nullable()();
  TextColumn get notes => text().nullable()();

  /// Printed on a badge as a QR code, scanned at sign-in (the PIN is still
  /// needed). v15.
  TextColumn get badgeCode => text().nullable()();

  /// Usual hours, minutes after midnight, for late and early on timesheets.
  /// v15.
  IntColumn get workStart => integer().nullable()();
  IntColumn get workEnd => integer().nullable()();

  /// The branch they work at; null for every branch (MDV-02). v17.
  TextColumn get branchId => text().nullable()();

  /// Typed before the PIN at sign-in ("101"), so the screen never lists
  /// names and two people may share a PIN. Not secret. v20.
  TextColumn get staffNumber => text().nullable()();

  /// An owner's recovery code, hashed like a PIN: sets a new PIN when the
  /// old one is forgotten. Null for none. v21.
  TextColumn get recoveryHash => text().nullable()();
}

/// Staff photos, small and kept apart from staff rows so they stay out of
/// sync payloads. Not synced; included in backups because they are in the
/// database.
// TODO(sync): upload photos as files once the API has storage for them.
@DataClassName('StaffPhotoRow')
class StaffPhotos extends Table {
  TextColumn get staffId => text().references(StaffMembers, #id)();
  BlobColumn get image => blob()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {staffId};
}

/// A cash-up for one device's drawer. Covers every sale after the previous
/// close up to [lastSaleNumber]. Amounts are pesewas.
@DataClassName('DayCloseRow')
class DayCloses extends Table with SyncColumns {
  /// The previous close's [closedAt]; null for the first close.
  DateTimeColumn get periodStart => dateTime().nullable()();
  DateTimeColumn get closedAt => dateTime()();

  /// The highest sale number (this device) the close covers. The next period
  /// starts after it. Exact where timestamps (whole seconds) are not.
  IntColumn get lastSaleNumber => integer()();
  TextColumn get closedById => text()();
  TextColumn get closedByName => text()();
  IntColumn get salesCount => integer()();
  IntColumn get voidedCount => integer()();
  IntColumn get salesTotal => integer()();
  IntColumn get cashTakings => integer()();
  IntColumn get momoTakings => integer()();
  IntColumn get creditTakings => integer()();
  IntColumn get openingFloat => integer()();
  IntColumn get expectedCash => integer()();
  IntColumn get countedCash => integer()();
  TextColumn get note => text().nullable()();

  /// The highest refund number (this device) the close covers. v7.
  IntColumn get lastRefundNumber => integer().withDefault(const Constant(0))();
  IntColumn get refundsTotal => integer().withDefault(const Constant(0))();

  /// Cash paid out for refunds; [expectedCash] takes it off. v7.
  IntColumn get cashRefunds => integer().withDefault(const Constant(0))();

  /// Takings by card, bank and the other methods. v7.
  IntColumn get otherTakings => integer().withDefault(const Constant(0))();
  IntColumn get roundingTotal => integer().withDefault(const Constant(0))();
  IntColumn get noSaleCount => integer().withDefault(const Constant(0))();

  /// Cash from customers that was not a sale: repayments, wallet top-ups,
  /// change kept. [expectedCash] includes it. v8.
  IntColumn get customerCash => integer().withDefault(const Constant(0))();

  /// The shift this close ends, and the notes and coins counted at open and
  /// close (JSON {"20000": 2, ...}). v9.
  TextColumn get shiftId => text().nullable()();
  TextColumn get floatCount => text().nullable()();
  TextColumn get cashCount => text().nullable()();

  /// Why the drawer was over or short, when more than the shop allows. v9.
  TextColumn get varianceReason => text().nullable()();

  /// Pesewas put in, taken out and dropped to the safe; and discounts. v9.
  IntColumn get payIns => integer().withDefault(const Constant(0))();
  IntColumn get payOuts => integer().withDefault(const Constant(0))();
  IntColumn get safeDrops => integer().withDefault(const Constant(0))();
  IntColumn get discountTotal => integer().withDefault(const Constant(0))();
}

/// Tamper-evident record of sensitive actions. Each row stores the hash of
/// the previous row on the same device, so editing or deleting a row breaks
/// the chain. Rows are never updated or deleted by the app.
@DataClassName('AuditRow')
class AuditLog extends Table with SyncColumns {
  /// Position in this device's chain, from 1. Unique with deviceId.
  IntColumn get seq => integer()();

  /// Milliseconds since epoch (UTC); hashed, so stored exactly.
  IntColumn get atMs => integer()();
  TextColumn get action => textEnum<AuditAction>()();
  TextColumn get actorId => text().nullable()();
  TextColumn get actorName => text().nullable()();
  TextColumn get approverId => text().nullable()();
  TextColumn get approverName => text().nullable()();
  TextColumn get entity => text().nullable()();
  TextColumn get entityId => text().nullable()();
  TextColumn get summary => text()();

  /// JSON, e.g. {"before": ..., "after": ...}.
  TextColumn get details => text().nullable()();
  TextColumn get prevHash => text()();
  TextColumn get hash => text()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {deviceId, seq},
      ];
}

/// Typed settings (see SettingsService). Row IDs are derived from the key
/// (and device, for device settings) so every device writes the same row.
@DataClassName('SettingRow')
class Settings extends Table with SyncColumns {
  TextColumn get key => text()();
  TextColumn get scope => textEnum<SettingScope>()();

  /// JSON-encoded value.
  TextColumn get value => text()();
}

/// Changes waiting to go to the server. Written in the same transaction as
/// the change itself. Not synced.
@DataClassName('OutboxRow')
class Outbox extends Table {
  IntColumn get seq => integer().autoIncrement()();
  /// Name of the synced table, e.g. "sales".
  TextColumn get entity => text()();
  TextColumn get recordId => text()();
  TextColumn get operation => textEnum<OutboxOperation>()();
  TextColumn get payload => text()();
  DateTimeColumn get createdAt => dateTime()();
}

/// Device-local settings (device ID, shop name). Not synced.
@DataClassName('MetaRow')
class Meta extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

/// An automatic promotion (SEL-06): applies itself when its conditions are
/// met. What it does is in [rule] (JSON, see domain/promotions.dart). v11.
@DataClassName('PromotionRow')
class Promotions extends Table with SyncColumns {
  TextColumn get name => text()();
  TextColumn get kind => textEnum<PromotionKind>()();
  TextColumn get rule => text()();

  /// First and last day it runs (dates at midnight); null for open-ended.
  DateTimeColumn get startsOn => dateTime().nullable()();
  DateTimeColumn get endsOn => dateTime().nullable()();

  /// Days of the week it runs: bit 0 Monday ... bit 6 Sunday.
  IntColumn get days => integer().withDefault(const Constant(127))();

  /// Minutes after midnight, for happy hours; null for all day.
  IntColumn get fromMinute => integer().nullable()();
  IntColumn get toMinute => integer().nullable()();

  /// Can apply together with other promotions.
  BoolColumn get stackable => boolean().withDefault(const Constant(false))();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
}

/// A gift voucher (CUS-05). Selling one is money in, not a sale: it is
/// spent later as a payment. Its balance is the sum of its entries. v12.
@DataClassName('GiftVoucherRow')
class GiftVouchers extends Table with SyncColumns {
  /// "SCP-7KQ4": printed, shared and typed or scanned at the till.
  TextColumn get code => text().unique()();

  /// Pesewas it was sold for.
  IntColumn get amount => integer()();

  /// The last day it can be spent; null for never.
  DateTimeColumn get expiresOn => dateTime().nullable()();
  TextColumn get customerId => text().nullable()();
  TextColumn get note => text().nullable()();
  TextColumn get byName => text()();
}

/// Money on a gift voucher: + when sold, - when spent. v12.
@DataClassName('VoucherEntryRow')
class VoucherEntries extends Table with SyncColumns {
  TextColumn get voucherId => text().references(GiftVouchers, #id)();
  TextColumn get kind => textEnum<VoucherEntryKind>()();
  IntColumn get amount => integer()();
  TextColumn get saleId => text().nullable()();

  /// How it was paid for, when sold (counts in the drawer at close).
  TextColumn get method => textEnum<PaymentMethod>().nullable()();
  TextColumn get methodName => text().nullable()();
  TextColumn get reference => text().nullable()();
  TextColumn get byName => text()();
}

/// An order to a supplier (INV-03). v14.
@DataClassName('PurchaseOrderRow')
class PurchaseOrders extends Table with SyncColumns {
  IntColumn get number => integer()();
  TextColumn get supplierId => text().references(Suppliers, #id)();
  TextColumn get status => textEnum<PurchaseOrderStatus>()();
  DateTimeColumn get expectedOn => dateTime().nullable()();
  TextColumn get note => text().nullable()();
  TextColumn get byName => text()();
}

@DataClassName('PurchaseOrderLineRow')
class PurchaseOrderLines extends Table with SyncColumns {
  TextColumn get orderId => text().references(PurchaseOrders, #id)();
  TextColumn get stockItemId => text().references(StockItems, #id)();

  /// Base units ordered, and received so far.
  IntColumn get quantity => integer()();
  IntColumn get received => integer().withDefault(const Constant(0))();

  /// Thousandths of a pesewa per base unit: the cost expected (last cost).
  IntColumn get unitCostMilli => integer().withDefault(const Constant(0))();
}

/// A batch received with its expiry date (INV-07). What is left of each
/// batch is worked out first-expiring-first-out from what is in stock. v14.
@DataClassName('StockBatchRow')
class StockBatches extends Table with SyncColumns {
  TextColumn get stockItemId => text().references(StockItems, #id)();
  TextColumn get receiptId => text().nullable()();
  TextColumn get batchNo => text().nullable()();
  DateTimeColumn get expiresOn => dateTime().nullable()();

  /// Base units received in this batch.
  IntColumn get quantity => integer()();
}

/// Clocking in and out (STF-04). v15.
@DataClassName('TimeEntryRow')
class TimeEntries extends Table with SyncColumns {
  TextColumn get staffId => text()();
  TextColumn get staffName => text()();
  DateTimeColumn get clockIn => dateTime()();
  DateTimeColumn get clockOut => dateTime().nullable()();

  /// Minutes on breaks so far, and when the current break started.
  IntColumn get breakMinutes => integer().withDefault(const Constant(0))();
  DateTimeColumn get breakStartedAt => dateTime().nullable()();
  TextColumn get note => text().nullable()();
}

/// On the hub: every change from every device, in order (MDV-01). Members
/// pull what is new since their cursor. Also the history of edits that lost
/// to a later one. Local to the hub, not synced. v16.
@DataClassName('HubChangeRow')
class HubChanges extends Table {
  IntColumn get seq => integer().autoIncrement()();
  TextColumn get entity => text()();
  TextColumn get recordId => text()();

  /// The row as its database columns, as JSON.
  TextColumn get row => text()();
  TextColumn get originDevice => text()();
  DateTimeColumn get at => dateTime()();
}

/// On the hub: devices paired with it (MDV-03). Local to the hub. v16.
@DataClassName('HubDeviceRow')
class HubDevices extends Table {
  TextColumn get deviceId => text()();
  TextColumn get name => text()();

  /// till | kitchen | display | owner
  TextColumn get role => text().withDefault(const Constant('till'))();

  /// The device's secret (base64): everything it sends is sealed with it.
  TextColumn get secret => text()();
  DateTimeColumn get pairedAt => dateTime()();
  DateTimeColumn get lastSeenAt => dateTime().nullable()();
  TextColumn get appVersion => text().nullable()();
  DateTimeColumn get revokedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {deviceId};
}

/// A shop location (MDV-02). Every shop has the main branch ([mainBranchId]);
/// a branch is the devices placed in it, so sales and stock movements belong
/// to the branch of the device that made them. v17.
@DataClassName('BranchRow')
class Branches extends Table with SyncColumns {
  TextColumn get name => text()();
  TextColumn get address => text().nullable()();
  TextColumn get phone => text().nullable()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
}

/// Which branch a device is in; the ID is the device's. A device not listed
/// is in the main branch. v17.
@DataClassName('DeviceBranchRow')
class DeviceBranches extends Table with SyncColumns {
  TextColumn get branchId => text()();
  TextColumn get deviceName => text().nullable()();
}

/// Stock sent from one branch to another (INV-10): in transit until the
/// other branch receives it. v17.
@DataClassName('StockTransferRow')
class StockTransfers extends Table with SyncColumns {
  TextColumn get fromBranch => text()();
  TextColumn get toBranch => text()();
  TextColumn get status => textEnum<TransferStatus>()();
  TextColumn get sentBy => text()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get receivedAt => dateTime().nullable()();
  TextColumn get receivedBy => text().nullable()();
}

@DataClassName('StockTransferLineRow')
class StockTransferLines extends Table with SyncColumns {
  TextColumn get transferId => text().references(StockTransfers, #id)();
  TextColumn get stockItemId => text().references(StockItems, #id)();
  IntColumn get quantitySent => integer()();

  /// Set when received; a difference from [quantitySent] is flagged.
  IntColumn get quantityReceived => integer().nullable()();

  /// Thousandths of a pesewa per base unit, when sent.
  IntColumn get unitCostMilli => integer().withDefault(const Constant(0))();
}
