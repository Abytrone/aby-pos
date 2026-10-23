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
}

/// What a variant (or an option) uses up each time it is sold.
@DataClassName('RecipeItemRow')
class RecipeItems extends Table with SyncColumns {
  TextColumn get variantId => text().nullable().references(ProductVariants, #id)();
  TextColumn get optionId => text().nullable().references(OptionItems, #id)();
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
  TextColumn get momoReference => text().nullable()();

  /// Credit only: customer name or phone.
  TextColumn get customer => text().nullable()();
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
