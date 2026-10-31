import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/app_version.dart';

/// Errors nothing else caught, written to a file the shop can send us from
/// Settings → About. Release builds are obfuscated: read the stack traces
/// with `flutter symbolize` and that version's build\symbols folder.
abstract final class CrashLog {
  /// Past this the log starts again, keeping the last one as `.old.log`.
  static const maxBytes = 512 * 1024;

  static Future<File> Function() file = _defaultFile;
  static Future<void> _writing = Future.value();

  static Future<File> _defaultFile() async =>
      File(p.join((await getApplicationSupportDirectory()).path, 'logs', 'aby_pos.log'));

  /// Catches framework, platform and zone errors from here on.
  static void install() {
    final shown = FlutterError.onError;
    FlutterError.onError = (details) {
      shown?.call(details);
      record(details.exception, details.stack, context: details.context?.toDescription());
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      record(error, stack);
      return true;
    };
  }

  /// Appends [error] to the log. Never throws: a failing log must not take
  /// the till down with it.
  static Future<void> record(Object error, StackTrace? stack, {String? context}) {
    debugPrint('Unhandled error: $error');
    final entry = StringBuffer()
      ..writeln('--- ${DateTime.now().toIso8601String()} · Aby $appVersion · ${Platform.operatingSystem}')
      ..writeln(context == null ? '$error' : '$context: $error')
      ..writeln(stack ?? '(no stack trace)');
    return _writing = _writing.then((_) => _append(entry.toString())).catchError((Object _) {});
  }

  static Future<void> _append(String entry) async {
    final f = await file();
    await f.parent.create(recursive: true);
    if (await f.exists() && await f.length() > maxBytes) {
      await f.rename(p.join(f.parent.path, '${p.basenameWithoutExtension(f.path)}.old.log'));
    }
    await f.writeAsString(entry, mode: FileMode.append, flush: true);
  }

  /// The log so far, or null when nothing has gone wrong.
  static Future<File?> latest() async {
    await _writing;
    final f = await file();
    return await f.exists() ? f : null;
  }
}
