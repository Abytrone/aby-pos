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
}
