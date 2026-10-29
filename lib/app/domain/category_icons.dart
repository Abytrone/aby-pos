import '../models/enums.dart';

/// Pictures for food and drink: the brand's Lucide category icons.
const foodIcons = [
  'ice-cream-cone',
  'ice-cream-bowl',
  'cup-soda',
  'milk',
  'coffee',
  'beer',
  'cookie',
  'croissant',
  'cake-slice',
  'candy',
  'sandwich',
  'pizza',
  'utensils',
  'apple',
  'egg',
  'wheat',
];

/// Pictures for every other kind of shop (Lucide, the same stroke).
const shopIcons = [
  'shopping-bag',
  'shirt',
  'gem',
  'sparkles',
  'scissors',
  'pill',
  'heart-pulse',
  'baby',
  'smartphone',
  'zap',
  'hammer',
  'wrench',
  'house',
  'book-open',
  'gift',
  'package',
];

/// Every picture a category can have, by name (the same names the back
/// office and web use).
const categoryIcons = [...foodIcons, ...shopIcons];

/// First match wins, so the narrow words come before the broad ones
/// ("hot drinks" is coffee, "milkshakes" are drinks, not milk). Words match
/// where a word starts, so "tea" finds "Teas" but not "Steak".
const _rules = <(String, List<String>)>[
  ('ice-cream-bowl', ['sundae', 'froyo', 'bowl', 'tub', 'cups', 'cup ']),
  ('ice-cream-cone', ['ice cream', 'icecream', 'gelato', 'cone', 'scoop', 'soft serve', 'fan ice']),
  ('coffee', ['coffee', 'tea', 'latte', 'espresso', 'cappuccino', 'hot drink', 'cafe', 'café', 'cocoa', 'milo']),
  ('beer', ['beer', 'alcohol', 'wine', 'spirit', 'liquor', 'cocktail', 'whisky', 'lager', 'stout']),
  ('cup-soda', ['milkshake', 'shake', 'smoothie', 'juice', 'soda', 'drink', 'mineral', 'water', 'beverage', 'sobolo', 'minerals']),
  ('milk', ['milk', 'dairy', 'yoghurt', 'yogurt', 'cheese']),
  ('croissant', ['pastry', 'pastries', 'croissant', 'meat pie', 'doughnut', 'donut', 'bofrot', 'bakery']),
  ('cake-slice', ['cupcake', 'cake', 'dessert', 'pudding', 'pie']),
  ('cookie', ['cookie', 'biscuit', 'snack', 'chips', 'crisps', 'plantain chips', 'waffle', 'crunch']),
  ('candy', ['sweet', 'candy', 'topping', 'chocolate', 'confection', 'extra', 'add-on', 'add on', 'sprinkle', 'sauce']),
  ('pizza', ['pizza']),
  ('sandwich', ['sandwich', 'burger', 'shawarma', 'wrap', 'sub', 'hot dog', 'toast']),
  // Dishes before grains: "Jollof rice" is a meal, "Rice" is a grain.
  ('utensils', ['jollof', 'waakye', 'banku', 'fufu', 'kenkey', 'fried rice', 'red red']),
  ('wheat', ['bread', 'flour', 'grain', 'cereal', 'rice', 'oats', 'pasta', 'spaghetti', 'gari', 'beans']),
  ('egg', ['egg', 'poultry', 'chicken', 'meat', 'fish', 'protein']),
  ('apple', ['fruit', 'veg', 'produce', 'fresh', 'tomato', 'onion', 'pepper']),
  ('utensils', ['food', 'meal', 'main', 'kitchen', 'plate', 'dish', 'lunch', 'dinner', 'breakfast', 'soup', 'chop', 'grill', 'side']),
  ('pill', ['medicine', 'pharma', 'drug', 'syrup', 'vitamin', 'chemist']),
  ('heart-pulse', ['first aid', 'health', 'medical', 'clinic', 'wellness']),
  ('baby', ['baby', 'babies', 'child', 'kid', 'infant', 'toddler', 'toy']),
  ('scissors', ['service', 'salon', 'barber', 'haircut', 'braid', 'nail', 'tailor', 'sewing']),
  ('sparkles', ['beauty', 'cosmetic', 'personal care', 'makeup', 'make-up', 'skin', 'hair', 'perfume', 'lotion']),
  ('shirt', ['women', 'men', 'ladies', 'clothes', 'clothing', 'fashion', 'dress', 'shirt', 'wear', 'fabric', 'kente', 'boutique', 'uniform']),
  ('gem', ['jewel', 'gold', 'bead', 'watch']),
  ('smartphone', ['phone', 'mobile', 'airtime', 'data', 'gadget', 'laptop', 'computer', 'electronic']),
  ('zap', ['electric', 'cable', 'bulb', 'battery', 'solar', 'power']),
  ('wrench', ['plumbing', 'repair', 'spare part', 'parts', 'mechanic', 'tool']),
  ('hammer', ['cement', 'block', 'roofing', 'building', 'hardware', 'paint', 'nail', 'timber', 'iron rod']),
  ('house', ['household', 'home', 'kitchenware', 'furniture', 'cleaning', 'detergent']),
  ('book-open', ['book', 'stationer', 'school', 'office']),
  ('gift', ['gift', 'party', 'present', 'decoration']),
  ('shopping-bag', ['grocer', 'provision', 'toiletr', 'shoes', 'bag', 'general', 'other', 'misc']),
];

/// The brand's default picture for each category colour, for a product
/// whose category is unknown.
String toneIcon(CategoryTone tone) => switch (tone) {
      CategoryTone.midnight => 'ice-cream-cone',
      CategoryTone.lime => 'candy',
      CategoryTone.blue => 'cup-soda',
      CategoryTone.coral => 'cookie',
      _ => 'shopping-bag',
    };

/// A picture for a category from its name ("Hot drinks" → coffee), else a
/// shopping bag, which suits any shop ("Phones", "Medicines"). Shops get a
/// finished-looking till before they pick.
String guessCategoryIcon(String name, CategoryTone tone) {
  // A trailing space marks a whole word ("cup " is not "cupcake").
  final n = '${name.toLowerCase().trim()} ';
  for (final (icon, words) in _rules) {
    if (words.any((w) => RegExp('(^|[^a-z])${RegExp.escape(w)}').hasMatch(n))) return icon;
  }
  return 'shopping-bag';
}

/// The icon to draw: the one picked, if it is still in the set, else a guess.
String categoryIconFor({required String name, required CategoryTone tone, String? picked}) =>
    picked != null && categoryIcons.contains(picked) ? picked : guessCategoryIcon(name, tone);
