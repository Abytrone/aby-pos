import 'dart:io';

import 'package:flutter/services.dart';

/// On macOS the sandbox forgets a folder the user picked when the app
/// quits. A bookmark made while it is allowed opens it again on a later
/// run (MainFlutterWindow.swift). Elsewhere there is nothing to do.
abstract final class FolderAccess {
  static const _channel = MethodChannel('aby/folder_access');

  static bool get needed => Platform.isMacOS;

  /// A bookmark for [path], made right after it was picked. Null when not
  /// needed or not possible.
  static Future<Uint8List?> bookmark(String path) async {
    if (!needed) return null;
    try {
      return await _channel.invokeMethod<Uint8List>('bookmark', path);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  /// Opens [bookmark] for the rest of the run. Returns the folder's path
  /// now (it may have been moved or renamed), or null when it cannot.
  static Future<String?> open(Uint8List bookmark) async {
    try {
      return await _channel.invokeMethod<String>('open', bookmark);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}
