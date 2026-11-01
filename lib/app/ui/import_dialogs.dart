import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../domain/catalogue_io.dart' show ImportProblem;
import '../theme/aby_colors.dart';
import '../theme/aby_icons.dart';
import '../theme/aby_theme.dart';
import 'dialogs.dart';
import 'l10n.dart';

/// Before the file picker: what the file looks like, column by column, and
/// a filled-in sample to start from. True: pick the file now.
Future<bool> showImportStart({
  required String title,
  required String intro,
  required List<String> steps,
  required Map<String, String> columns,
  required Set<String> requiredColumns,
  required VoidCallback onSample,
  String? startFromMineLabel,
  VoidCallback? onStartFromMine,
  required String footer,
}) async =>
    await Get.dialog<bool>(Builder(builder: (context) {
      final c = Theme.of(context).extension<AbyColors>()!;
      final l = context.l10n;
      Widget step(int n, String text) => Padding(
            padding: const EdgeInsets.only(bottom: AbySpace.s2),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: c.surfaceSunken, shape: BoxShape.circle),
                child: Text('$n', style: AbyText.caption.copyWith(color: c.ink, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: AbySpace.s3),
              Expanded(child: Text(text, style: AbyText.body.copyWith(color: c.ink))),
            ]),
          );
      return AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(intro, style: AbyText.body.copyWith(color: c.inkMuted)),
              const SizedBox(height: AbySpace.s4),
              for (final (i, s) in steps.indexed) step(i + 1, s),
              const SizedBox(height: AbySpace.s2),
              OutlinedButton.icon(
                onPressed: onSample,
                icon: AbyIcon(AbyIcons.download, size: 20, color: c.ink),
                label: Text(l.importDownloadSample),
              ),
              if (onStartFromMine != null && startFromMineLabel != null)
                TextButton.icon(
                  onPressed: onStartFromMine,
                  icon: AbyIcon(AbyIcons.fileText, size: 20, color: c.ink),
                  label: Text(startFromMineLabel),
                ),
              const SizedBox(height: AbySpace.s4),
              Text(l.importColumns.toUpperCase(), style: AbyText.label.copyWith(color: c.inkMuted)),
              const SizedBox(height: AbySpace.s2),
              Container(
                decoration: BoxDecoration(color: c.surfaceSunken, borderRadius: BorderRadius.circular(AbyRadius.md)),
                padding: const EdgeInsets.symmetric(horizontal: AbySpace.s3, vertical: AbySpace.s2),
                child: Column(children: [
                  for (final MapEntry(key: name, value: help) in columns.entries)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: AbySpace.s1),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        SizedBox(
                          width: 96,
                          child: Text(
                            name,
                            style: AbyText.receipt.copyWith(
                              color: c.ink,
                              fontWeight: requiredColumns.contains(name) ? FontWeight.w700 : null,
                            ),
                          ),
                        ),
                        Expanded(child: Text(help, style: AbyText.caption.copyWith(color: c.inkMuted))),
                      ]),
                    ),
                ]),
              ),
              const SizedBox(height: AbySpace.s2),
              Text(footer, style: AbyText.caption.copyWith(color: c.inkMuted)),
            ]),
          ),
        ),
        actions: [
          DialogButtons(children: [
            OutlinedButton(onPressed: () => goBack<bool>(), child: Text(l.commonCancel)),
            FilledButton.icon(
              onPressed: () => goBack<bool>(result: true),
              icon: AbyIcon(AbyIcons.upload, size: 20, color: c.onPrimary),
              label: Text(l.importPick),
            ),
          ]),
        ],
      );
    })) ==
    true;

/// What a file would do, with its problems, and Import to save it all.
/// [onApply] returns true when saved.
Future<void> showImportPreview({
  required String title,
  required String summary,
  List<String> notes = const [],
  required List<ImportProblem> problems,
  required bool canApply,
  required Future<bool> Function() onApply,
}) =>
    Get.dialog<void>(Builder(builder: (context) {
      final c = Theme.of(context).extension<AbyColors>()!;
      final l = context.l10n;
      return AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(summary, style: AbyText.body.copyWith(color: c.ink)),
              for (final n in notes)
                Padding(
                  padding: const EdgeInsets.only(top: AbySpace.s2),
                  child: Text(n, style: AbyText.caption.copyWith(color: c.inkMuted)),
                ),
              if (problems.isNotEmpty) ...[
                const SizedBox(height: AbySpace.s3),
                Text(l.importProblems(problems.length).toUpperCase(), style: AbyText.label.copyWith(color: c.danger)),
                for (final p in problems.take(30))
                  Text(l.importRow(p.row, p.message), style: AbyText.caption.copyWith(color: c.danger)),
                const SizedBox(height: AbySpace.s3),
                Text(l.importFixHint, style: AbyText.caption.copyWith(color: c.inkMuted)),
              ],
            ]),
          ),
        ),
        actions: [
          DialogButtons(children: [
            OutlinedButton(onPressed: () => goBack<void>(), child: Text(l.commonCancel)),
            FilledButton(
              onPressed: canApply
                  ? () async {
                      if (await onApply()) goBack<void>();
                    }
                  : null,
              child: Text(l.importApply),
            ),
          ]),
        ],
      );
    }));
