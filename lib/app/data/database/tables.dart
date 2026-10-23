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
}

@DataClassName('ProductRow')
class Products extends Table with SyncColumns {
  TextColumn get categoryId => text().references(Categories, #id)();
  TextColumn get name => text()();
  TextColumn get detail => text().nullable()();

  /// Pesewas.
  IntColumn get basePrice => integer()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

@DataClassName('VariantRow')
class ProductVariants extends Table with SyncColumns {
  TextColumn get productId => text().references(Products, #id)();
  TextColumn get name => text()();

  /// Pesewas.
  IntColumn get price => integer()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

@DataClassName('AddonRow')
class Addons extends Table with SyncColumns {
  TextColumn get name => text()();

  /// Pesewas.
  IntColumn get price => integer()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

@DataClassName('ProductAddonRow')
class ProductAddons extends Table with SyncColumns {
  TextColumn get productId => text().references(Products, #id)();
  TextColumn get addonId => text().references(Addons, #id)();
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
  TextColumn get addons =>
      text().map(const SoldAddonsConverter()).withDefault(const Constant('[]'))();
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
  TextColumn get productId => text().references(Products, #id)();
  TextColumn get variantId => text().nullable().references(ProductVariants, #id)();
  IntColumn get quantityChange => integer()();
  TextColumn get reason => textEnum<StockReason>()();
  TextColumn get saleId => text().nullable().references(Sales, #id)();
  TextColumn get note => text().nullable()();
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
