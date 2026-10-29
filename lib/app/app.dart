import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'bindings/initial_binding.dart';
import 'core/settings.dart';
import 'data/database/app_database.dart';
import 'routes/app_pages.dart';
import 'services/session_service.dart';
import 'services/settings_service.dart';
import 'services/training_service.dart';
import 'theme/aby_theme.dart';
import 'ui/l10n.dart';

/// The app root. Can rebuild itself from scratch (new services, database
/// reopened) after a restore: see [AppRestarter].
class AbyApp extends StatefulWidget {
  const AbyApp({super.key, this.openDatabase});

  /// Tests open an in-memory database; called again on every restart.
  final AppDatabase Function()? openDatabase;

  @override
  State<AbyApp> createState() => _AbyAppState();
}

class _AbyAppState extends State<AbyApp> {
  var _generation = 0;

  @override
  void initState() {
    super.initState();
    AppRestarter._state = this;
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    if (AppRestarter._state == this) AppRestarter._state = null;
    super.dispose();
  }

  bool _onKey(KeyEvent event) {
    _touch();
    return false;
  }

  void _touch() {
    if (Get.isRegistered<SessionService>()) Get.find<SessionService>().touch();
  }

  Future<void> _restart() async {
    await Get.deleteAll(force: true);
    Get.reset();
    setState(() => _generation++);
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      key: ValueKey(_generation),
      title: 'Aby',
      debugShowCheckedModeBanner: false,
      theme: AbyTheme.light,
      darkTheme: AbyTheme.dark,
      themeMode: ThemeMode.system,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      initialBinding: InitialBinding(database: widget.openDatabase?.call()),
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,
      builder: (context, child) => Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => _touch(),
        child: _TextSize(child: _TrainingBand(child: child ?? const SizedBox.shrink())),
      ),
    );
  }
}

/// A yellow "Training" band over every screen while in training mode.
class _TrainingBand extends StatelessWidget {
  const _TrainingBand({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<TrainingService>()) return child;
    final training = Get.find<TrainingService>();
    return Obx(() {
      if (!training.active.value) return child;
      return Column(children: [
        Material(
          color: const Color(0xFFFFD233),
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: 28,
              width: double.infinity,
              child: Center(
                child: Text(
                  context.l10n.trainingBand,
                  style: const TextStyle(color: Color(0xFF101322), fontWeight: FontWeight.w800, letterSpacing: 1),
                ),
              ),
            ),
          ),
        ),
        Expanded(child: child),
      ]);
    });
  }
}

/// Applies the "large text" device setting.
class _TextSize extends StatelessWidget {
  const _TextSize({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<SettingsService>()) return child;
    final settings = Get.find<SettingsService>();
    return Obx(() {
      final large = settings.get(AppSettings.largeText);
      final media = MediaQuery.of(context);
      return MediaQuery(
        data: media.copyWith(
          textScaler: large ? media.textScaler.clamp(minScaleFactor: 1.2) : media.textScaler,
        ),
        child: child,
      );
    });
  }
}

/// Restarts the whole app in place: every service and controller is thrown
/// away and the database reopened. Used after a restore.
abstract final class AppRestarter {
  static _AbyAppState? _state;

  static Future<void> restart() async => _state?._restart();

  /// Applies the device's theme setting.
  static void applyTheme(String mode) => Get.changeThemeMode(switch (mode) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      });
}
