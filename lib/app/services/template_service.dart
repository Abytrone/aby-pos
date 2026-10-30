import '../core/settings.dart';
import '../data/repositories/catalog_repository.dart';
import '../domain/business_templates.dart';
import '../models/drafts.dart';
import '../models/staff.dart';
import 'settings_service.dart';

/// Sets a new shop up for its kind of business (APP-04), once, at setup.
class TemplateService {
  TemplateService(this._catalog, this._settings);

  final CatalogRepository _catalog;
  final SettingsService _settings;

  /// Applies [type]: its starting categories (any the shop has already are
  /// kept) and its features.
  Future<void> apply(BusinessType type, {required Staff by}) async {
    final t = BusinessTemplate.of(type);
    await _settings.set(AppSettings.shopType, type.name, by: by);
    final existing = {for (final c in await _catalog.categories(includeInactive: true)) c.name.toLowerCase()};
    for (final (name, tone) in t.categories) {
      if (!existing.contains(name.toLowerCase())) await _catalog.saveCategory(CategoryDraft(name: name, tone: tone), by: by);
    }
    for (final (setting, value) in t.settings) {
      await _settings.set(setting, value, by: by);
    }
  }
}
