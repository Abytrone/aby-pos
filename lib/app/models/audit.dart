/// What the audit log records. Stored by name; never rename a value.
enum AuditAction {
  signedIn,
  signInFailed,
  lockedOut,
  locked,
  approvalRefused,
  saleVoided,
  dayClosed,
  staffAdded,
  staffPinChanged,
  staffDetailsChanged,
  staffRoleChanged,
  staffDeactivated,
  staffReactivated,
  roleCreated,
  roleUpdated,
  roleDeleted,
  settingChanged,
  backupCreated,
  backupExported,
  backupRestored,
  productCreated,
  productUpdated,
  productArchived,
  productRestored,
  priceChanged,
  categorySaved,
  optionGroupSaved,
  taxRateSaved,
  stockItemSaved,
  stockReceived,
  stockAdjusted,
  stockWasted,
  stockProduced,
  purchaseOrderSaved,
  stockCountPosted,
  supplierSaved,
  supplierPaid,
  priceScheduled,
  pricesBulkChanged,
  barcodesGenerated,
  catalogueImported,
  stockImported,
  productsFromStock,
  cartLinesRemoved,
  cartCleared,
  priceOverridden,
  discountsGiven,
  orderParked,
  parkedOrderDiscarded,
  discountSaved,
  promotionSaved,
  reasonSaved,
  refundGiven,
  noSale,
  payMethodSaved,
  customerSaved,
  customerCreditLimit,
  customerRepaid,
  walletTopUp,
  voucherIssued,
  creditWrittenOff,
  cashPaidIn,
  cashPaidOut,
  safeDrop,
  bankDeposit,
  shiftOpened,
  momoChecked,
  expenseAdded,
  expenseCategorySaved,
  ownerDrawing,
  ownerCapital,
  branchSaved,
  deviceBranchChanged,
  stockTransferSent,
  stockTransferReceived,
  stockTransferCancelled,
  branchDataMerged,
  accountsExported,
  priceScheduleCancelled,
  stockCountCancelled,
  receiptReprinted,
  trainingStarted,
  momoChargesSet,
  licenseActivated,
  staffRecoveryCodeMade,
  staffPinReset,
  staffPinResetCancelled,
  timeEntryCorrected;

  /// Actions an owner should notice first.
  bool get isSensitive => const {
        AuditAction.signInFailed,
        AuditAction.lockedOut,
        AuditAction.staffPinReset,
        AuditAction.timeEntryCorrected,
        AuditAction.approvalRefused,
        AuditAction.saleVoided,
        AuditAction.staffRoleChanged,
        AuditAction.roleUpdated,
        AuditAction.roleDeleted,
        AuditAction.backupRestored,
        AuditAction.priceChanged,
        AuditAction.pricesBulkChanged,
        AuditAction.stockAdjusted,
        AuditAction.stockWasted,
        AuditAction.stockCountPosted,
        AuditAction.supplierPaid,
        AuditAction.cartLinesRemoved,
        AuditAction.cartCleared,
        AuditAction.priceOverridden,
        AuditAction.parkedOrderDiscarded,
        AuditAction.refundGiven,
        AuditAction.noSale,
        AuditAction.customerCreditLimit,
        AuditAction.creditWrittenOff,
        AuditAction.cashPaidOut,
        AuditAction.bankDeposit,
        AuditAction.ownerDrawing,
      }.contains(this);
}

class AuditEntry {
  const AuditEntry({
    required this.id,
    required this.seq,
    required this.at,
    required this.deviceId,
    required this.action,
    required this.summary,
    this.actorId,
    this.actorName,
    this.approverId,
    this.approverName,
    this.entity,
    this.entityId,
    this.details,
  });

  final String id;

  /// Position in this device's chain.
  final int seq;
  final DateTime at;
  final String deviceId;
  final AuditAction action;
  final String? actorId;
  final String? actorName;
  final String? approverId;
  final String? approverName;
  final String? entity;
  final String? entityId;

  /// Plain-words line, e.g. "Voided #00012 (GH₵ 37.00)".
  final String summary;

  /// Before/after values, for changes.
  final Map<String, dynamic>? details;
}

/// Result of checking the audit chain.
class AuditChainStatus {
  const AuditChainStatus.ok(this.checked) : brokenAtSeq = null;
  const AuditChainStatus.broken(this.checked, int this.brokenAtSeq);

  final int checked;
  final int? brokenAtSeq;

  bool get isIntact => brokenAtSeq == null;
}
