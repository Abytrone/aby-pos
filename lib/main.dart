import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app/bindings/initial_binding.dart';
import 'app/routes/app_pages.dart';
import 'app/theme/aby_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AbyApp());
}

class AbyApp extends StatelessWidget {
  const AbyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Aby',
      debugShowCheckedModeBanner: false,
      theme: AbyTheme.light,
      darkTheme: AbyTheme.dark,
      themeMode: ThemeMode.system,
      initialBinding: InitialBinding(),
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,
    );
  }
}
