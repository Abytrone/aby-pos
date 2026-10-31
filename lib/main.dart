import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/services/crash_log.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  CrashLog.install();
  runApp(const AbyApp());
}
