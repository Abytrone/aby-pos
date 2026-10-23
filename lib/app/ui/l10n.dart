import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../l10n/app_localizations.dart';

export '../../l10n/app_localizations.dart';

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// For controllers and services, which have no BuildContext.
AppLocalizations appL10n() {
  final locale = Get.locale ?? const Locale('en');
  try {
    return lookupAppLocalizations(locale);
  } catch (_) {
    return lookupAppLocalizations(const Locale('en'));
  }
}
