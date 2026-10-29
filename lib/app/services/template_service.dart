import '../core/settings.dart';
import '../data/database/app_database.dart';
import '../data/repositories/catalog_repository.dart';
import '../domain/business_templates.dart';
import '../models/drafts.dart';
import '../models/staff.dart';
import 'settings_service.dart';

/// Sets a new shop up for its kind of business (APP-04), once, at setup.
class TemplateService {
  TemplateService(this._db, this._catalog, this._settings);

  final AppDatabase _db;
  final CatalogRepository _catalog;
  final SettingsService _settings;

  /// Applies [type]. Other kinds than the ice cream shop lose the sample
  /// menu first, but only while nothing has been sold.
  Future<void> apply(BusinessType type, {required Staff by}) async {
    final t = BusinessTemplate.of(type);
    await _settings.set(AppSettings.shopType, type.name, by: by);
    if (!t.keepSampleMenu) {
      final sold = await _db.customSelect('SELECT COUNT(*) AS n FROM sales').getSingle();
      if (sold.read<int>('n') == 0) await _clearSampleMenu();
      final existing = {for (final c in await _catalog.categories(includeInactive: true)) c.name.toLowerCase()};
      for (final (name, tone) in t.categories) {
        if (!existing.contains(name.toLowerCase())) await _catalog.saveCategory(CategoryDraft(name: name, tone: tone), by: by);
      }
    }
    for (final (setting, value) in t.settings) {
      await _settings.set(setting, value, by: by);
    }
  }

  /// The sample ice cream menu, its stock and recipes (the tax rates stay).
  /// The sample rows were never queued for sync, so they can simply go.
  Future<void> _clearSampleMenu() => _db.transaction(() async {
        for (final table in [
          'recipe_items',
          'product_option_groups',
          'option_items',
          'option_groups',
          'barcodes',
          'product_taxes',
          'product_variants',
          'products',
          'categories',
          'stock_batches',
          'stock_movements',
          'stock_items',
        ]) {
          await _db.customStatement('DELETE FROM $table');
        }
      });
}
