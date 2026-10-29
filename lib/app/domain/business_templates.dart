import '../core/settings.dart';
import '../models/enums.dart';

/// The kinds of shop Aby sets itself up for (APP-04).
enum BusinessType { iceCream, provision, chopBar, pharmacy, salon, phones, boutique, building, other }

/// What a kind of shop starts with: categories to fill in, and which
/// features are on. Everything can be changed later (Settings → Features).
class BusinessTemplate {
  const BusinessTemplate({required this.categories, this.settings = const [], this.keepSampleMenu = false});

  /// (name, colour) of the starting categories.
  final List<(String, CategoryTone)> categories;

  /// Settings switched on (or set) for this kind of shop.
  final List<(Setting<Object>, Object)> settings;

  /// The ice cream shop keeps the full sample menu, stock and recipes.
  final bool keepSampleMenu;

  static BusinessTemplate of(BusinessType t) => switch (t) {
        BusinessType.iceCream => const BusinessTemplate(
            keepSampleMenu: true,
            categories: [],
            settings: [(AppSettings.loyaltyStyle, 'stamps'), (AppSettings.expiryByDefault, true)],
          ),
        BusinessType.provision => const BusinessTemplate(
            categories: [
              ('Drinks', CategoryTone.blue),
              ('Provisions', CategoryTone.lime),
              ('Toiletries', CategoryTone.coral),
              ('Snacks', CategoryTone.midnight),
            ],
            settings: [(AppSettings.expiryByDefault, true)],
          ),
        BusinessType.chopBar => const BusinessTemplate(
            categories: [
              ('Food', CategoryTone.coral),
              ('Soups', CategoryTone.lime),
              ('Drinks', CategoryTone.blue),
              ('Extras', CategoryTone.midnight),
            ],
            settings: [(AppSettings.orderTypes, true), (AppSettings.ordersOn, true)],
          ),
        BusinessType.pharmacy => const BusinessTemplate(
            categories: [
              ('Medicines', CategoryTone.blue),
              ('Personal care', CategoryTone.lime),
              ('Baby', CategoryTone.coral),
              ('First aid', CategoryTone.midnight),
            ],
            settings: [(AppSettings.expiryByDefault, true)],
          ),
        BusinessType.salon => const BusinessTemplate(
            categories: [('Services', CategoryTone.coral), ('Products', CategoryTone.blue)],
            settings: [(AppSettings.commissionMode, 'percent'), (AppSettings.commissionPercent, 10)],
          ),
        BusinessType.phones => const BusinessTemplate(
            categories: [
              ('Phones', CategoryTone.midnight),
              ('Accessories', CategoryTone.blue),
              ('Repairs', CategoryTone.coral),
              ('Airtime and data', CategoryTone.lime),
            ],
          ),
        BusinessType.boutique => const BusinessTemplate(
            categories: [
              ('Women', CategoryTone.coral),
              ('Men', CategoryTone.blue),
              ('Children', CategoryTone.lime),
              ('Shoes and bags', CategoryTone.midnight),
            ],
          ),
        BusinessType.building => const BusinessTemplate(
            categories: [
              ('Cement and blocks', CategoryTone.midnight),
              ('Roofing', CategoryTone.coral),
              ('Plumbing', CategoryTone.blue),
              ('Electrical', CategoryTone.lime),
              ('Paint and tools', CategoryTone.amber),
            ],
          ),
        BusinessType.other => const BusinessTemplate(categories: [('General', CategoryTone.blue)]),
      };
}
