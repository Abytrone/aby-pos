// How to wire the theme and widgets into your app (lib/main.dart). With GetX, use GetMaterialApp the same way.
import 'package:flutter/material.dart';
import 'theme/aby_theme.dart';
import 'theme/aby_widgets.dart';

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
      home: const _Demo(),
    );
  }
}

class _Demo extends StatefulWidget {
  const _Demo();
  @override
  State<_Demo> createState() => _DemoState();
}

class _DemoState extends State<_Demo> {
  var view = AbyProductView.grid;
  var count = 0;

  @override
  Widget build(BuildContext context) {
    const image = AssetImage('assets/samples/vanilla-cone.png');
    return Scaffold(
      appBar: AppBar(title: const Text('Ice cream'), actions: [
        const AbySyncBadge(waiting: 3, offline: true),
        const SizedBox(width: AbySpace.s3),
        AbyViewToggle(value: view, onChanged: (v) => setState(() => view = v)),
        const SizedBox(width: AbySpace.s4),
      ]),
      body: Padding(
        padding: const EdgeInsets.all(AbySpace.s4),
        child: view == AbyProductView.grid
            ? SizedBox(
                width: AbySize.tileMin + 20,
                child: AbyProductTile(name: 'Vanilla cone', detail: 'Single scoop', price: 15, count: count, image: image, onTap: () => setState(() => count++)),
              )
            : AbyProductRow(name: 'Vanilla cone', detail: 'Single scoop', price: 15, count: count, image: image, onTap: () => setState(() => count++)),
      ),
    );
  }
}
