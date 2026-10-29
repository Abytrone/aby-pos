import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../domain/documents/pdf_brand.dart';
import '../domain/documents/table_doc.dart';
import '../domain/documents/xlsx.dart';
import '../services/pdf_brand_loader.dart';
import '../theme/aby_colors.dart';
import '../theme/aby_theme.dart';
import 'dialogs.dart';
import 'files.dart';
import 'l10n.dart';

enum ExportFormat { excel, pdf, csv }

/// The format picked last time, offered first next time.
ExportFormat _last = ExportFormat.excel;

/// Exports [doc] as an Excel workbook, a PDF or CSV, shared or saved to a
/// folder, all picked in one dialog. [csv] replaces the CSV made from the
/// table, for files Aby or other software reads back (the product list);
/// [csvImports] says so in the dialog. CSV is offered for a single table or
/// when [csv] is given. Returns true when the file went somewhere.
Future<bool> exportDocument(
  TableDoc doc, {
  required String fileStem,
  String? csv,
  bool csvImports = false,
  String? shareText,
  String? eyebrow,
}) async {
  final formats = [ExportFormat.excel, ExportFormat.pdf, if (csv != null || doc.sheets.length == 1) ExportFormat.csv];
  final choice = await Get.dialog<(ExportFormat, FileDestination)>(_ExportDialog(
    title: doc.title,
    formats: formats,
    initial: formats.contains(_last) ? _last : formats.first,
    csvImports: csvImports,
  ));
  if (choice == null) return false;
  final (format, where) = choice;
  _last = format;
  showProgress(appL10n().exportMaking);
  final Uint8List bytes;
  try {
    bytes = switch (format) {
      ExportFormat.excel => Xlsx.build(doc),
      ExportFormat.pdf => await DocPdf.build(doc, await loadPdfBrand(), logo: shopLogo(), eyebrow: eyebrow),
      ExportFormat.csv => csvBytes(csv ?? doc.sheets.single.toCsv()),
    };
  } finally {
    hideProgress();
  }
  final ext = switch (format) { ExportFormat.excel => 'xlsx', ExportFormat.pdf => 'pdf', ExportFormat.csv => 'csv' };
  return sendBytes('$fileStem.$ext', bytes, where, text: shareText);
}

class _ExportDialog extends StatefulWidget {
  const _ExportDialog({required this.title, required this.formats, required this.initial, required this.csvImports});

  final String title;
  final List<ExportFormat> formats;
  final ExportFormat initial;
  final bool csvImports;

  @override
  State<_ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<_ExportDialog> {
  late var _format = widget.initial;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
      title: Text(l.exportTitle(widget.title)),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            for (final f in widget.formats)
              Padding(
                padding: const EdgeInsets.only(bottom: AbySpace.s2),
                child: _FormatCard(
                  icon: switch (f) {
                    ExportFormat.excel => Icons.grid_on_outlined,
                    ExportFormat.pdf => Icons.picture_as_pdf_outlined,
                    ExportFormat.csv => Icons.description_outlined,
                  },
                  title: switch (f) { ExportFormat.excel => l.exportExcel, ExportFormat.pdf => l.receiptPdf, ExportFormat.csv => 'CSV' },
                  help: switch (f) {
                    ExportFormat.excel => l.exportExcelHelp,
                    ExportFormat.pdf => l.exportPdfHelp,
                    ExportFormat.csv => widget.csvImports ? l.exportCsvImportHelp : l.exportCsvHelp,
                  },
                  selected: f == _format,
                  onTap: () => setState(() => _format = f),
                ),
              ),
          ]),
        ),
      ),
      actions: [
        DialogButtons(children: [
          TextButton(onPressed: () => goBack<(ExportFormat, FileDestination)>(), child: Text(l.commonCancel)),
          OutlinedButton.icon(
            onPressed: () => goBack(result: (_format, FileDestination.folder)),
            icon: const Icon(Icons.folder_outlined),
            label: Text(l.exportSave),
          ),
          FilledButton.icon(
            onPressed: () => goBack(result: (_format, FileDestination.share)),
            icon: const Icon(Icons.share_outlined),
            label: Text(l.exportShare),
          ),
        ]),
      ],
    );
  }
}

/// One format to pick: an icon, its name and what it is good for.
class _FormatCard extends StatelessWidget {
  const _FormatCard({required this.icon, required this.title, required this.help, required this.selected, required this.onTap});

  final IconData icon;
  final String title;
  final String help;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AbyRadius.md),
      side: BorderSide(color: selected ? c.blue : c.line, width: selected ? 2 : 1.5),
    );
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? c.blueSoft : c.surfaceRaised,
        shape: shape,
        child: InkWell(
          customBorder: shape,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AbySize.tapPos),
            child: Padding(
              padding: const EdgeInsets.all(AbySpace.s3),
              child: Row(children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: c.limeSoft, borderRadius: BorderRadius.circular(AbyRadius.sm)),
                  child: Icon(icon, color: c.limeInk),
                ),
                const SizedBox(width: AbySpace.s3),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(title, style: AbyText.tile.copyWith(color: c.ink)),
                    Text(help, style: AbyText.caption.copyWith(color: c.inkMuted)),
                  ]),
                ),
                if (selected) ...[const SizedBox(width: AbySpace.s2), Icon(Icons.check_circle, color: c.blue)],
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
