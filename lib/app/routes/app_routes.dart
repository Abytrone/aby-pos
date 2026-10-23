abstract final class Routes {
  static const start = '/start';
  static const setup = '/setup';
  static const signIn = '/sign-in';

  /// Sell and Manage, after sign-in.
  static const shell = '/';
  static const checkout = '/checkout';
  static const closeDay = '/close-day';

  /// Argument: the staff ID.
  static const staffProfile = '/staff-profile';

  /// Argument: the product ID, or null for a new product.
  static const productEditor = '/product';

  /// Argument: the stock item ID.
  static const stockItem = '/stock-item';

  static const receive = '/receive';

  /// Argument: the stock count ID.
  static const stockCount = '/stock-count';

  /// Argument: the supplier ID.
  static const supplier = '/supplier';
}
