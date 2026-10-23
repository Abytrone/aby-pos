// How to wire the theme into your app (lib/main.dart).
import 'package:flutter/material.dart';
import 'theme/aby_theme.dart';

void main() => runApp(const AbyApp());

class AbyApp extends StatelessWidget {
  const AbyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aby',
      theme: AbyTheme.light,
      darkTheme: AbyTheme.dark,
      themeMode: ThemeMode.system,
      home: const Scaffold(body: Center(child: AbySyncBadge(waiting: 3, offline: true))),
    );
  }
}
