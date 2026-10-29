import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pdf/widgets.dart' as pw;

import '../core/settings.dart';
import '../domain/documents/pdf_brand.dart';
import 'settings_service.dart';

Future<PdfBrand>? _brand;

/// The app's fonts and mark for PDFs, read once. Falls back to the PDF's
/// built-in fonts if they cannot be read, so a document is always made.
Future<PdfBrand> loadPdfBrand() => _brand ??= _load();

Future<PdfBrand> _load() async {
  try {
    Future<pw.Font> font(String file) async => pw.Font.ttf(await rootBundle.load('fonts/$file.ttf'));
    return PdfBrand(
      sans: await font('Figtree-Regular'),
      sansSemi: await font('Figtree-SemiBold'),
      sansBold: await font('Figtree-Bold'),
      sansBlack: await font('Figtree-Black'),
      mono: await font('JetBrainsMono-Regular'),
      monoBold: await font('JetBrainsMono-Bold'),
      extra: [await font('AbyExtra-Regular')],
      extraBold: [await font('AbyExtra-Bold')],
      mark: await rootBundle.loadString('assets/brand/aby-mark.svg'),
      markReversed: await rootBundle.loadString('assets/brand/aby-mark-reversed.svg'),
    );
  } catch (e) {
    debugPrint('PDF fonts could not be read, using the built-in ones: $e');
    _brand = null;
    return PdfBrand.plain();
  }
}

/// The shop's receipt logo (PNG) for the top of A4 documents; null when
/// there is none.
Uint8List? shopLogo() {
  if (!Get.isRegistered<SettingsService>()) return null;
  final logo = Get.find<SettingsService>().get(AppSettings.receiptLogo);
  if (logo.isEmpty) return null;
  try {
    return base64Decode(logo);
  } on FormatException {
    return null;
  }
}
