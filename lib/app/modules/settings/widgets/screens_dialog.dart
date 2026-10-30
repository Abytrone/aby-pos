import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../services/display/display_service.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/dialogs.dart';
import '../../../ui/l10n.dart';

/// The links for the customer display, the prep screen and "Now serving",
/// with QR codes to scan from a tablet or phone on the same Wi-Fi.
Future<void> showScreenLinks() async {
  final display = Get.find<DisplayService>();
  final addresses = await DisplayService.addresses();
  await Get.dialog<void>(_ScreenLinks(display: display, addresses: addresses));
}

class _ScreenLinks extends StatefulWidget {
  const _ScreenLinks({required this.display, required this.addresses});

  final DisplayService display;
  final List<String> addresses;

  @override
  State<_ScreenLinks> createState() => _ScreenLinksState();
}

class _ScreenLinksState extends State<_ScreenLinks> {
  late String? _address = widget.addresses.firstOrNull;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = Theme.of(context).extension<AbyColors>()!;
    final d = widget.display;
    final address = _address;
    Widget link(String title, String help, String url) => Card(
          margin: const EdgeInsets.only(bottom: AbySpace.s3),
          child: Padding(
            padding: const EdgeInsets.all(AbySpace.s3),
            child: Row(children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(AbySpace.s1),
                child: QrImageView(data: url, size: 92, padding: EdgeInsets.zero),
              ),
              const SizedBox(width: AbySpace.s3),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: AbyText.heading.copyWith(color: c.ink)),
                  Text(help, style: AbyText.caption.copyWith(color: c.inkMuted)),
                  SelectableText(url, style: AbyText.receipt.copyWith(color: c.ink)),
                ]),
              ),
              IconButton(
                tooltip: l.commonCopy,
                icon: const Icon(Icons.copy),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: url));
                  showMessage(l.commonCopied, tone: MessageTone.success);
                },
              ),
            ]),
          ),
        );
    return AlertDialog(
      title: Text(l.screensTitle),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (!d.running)
              Text(l.screensNotRunning, style: AbyText.body.copyWith(color: c.danger))
            else if (address == null)
              Text(l.screensNoNetwork, style: AbyText.body.copyWith(color: c.danger))
            else ...[
              Text(l.screensHelp, style: AbyText.caption.copyWith(color: c.inkMuted)),
              if (widget.addresses.length > 1) ...[
                const SizedBox(height: AbySpace.s2),
                DropdownButtonFormField<String>(
                  initialValue: address,
                  decoration: InputDecoration(labelText: l.screensNetwork, isDense: true),
                  items: [for (final a in widget.addresses) DropdownMenuItem(value: a, child: Text(a))],
                  onChanged: (a) => setState(() => _address = a),
                ),
              ],
              const SizedBox(height: AbySpace.s3),
              link(l.screensCustomer, l.screensCustomerHelp, d.links(address).customer),
              link(l.screensPrep, l.screensPrepHelp, d.links(address).prep),
              link(l.screensServing, l.screensServingHelp, d.links(address).serving),
            ],
          ]),
        ),
      ),
      actions: [
        DialogButtons(children: [
              if (d.running)
            TextButton(
              onPressed: () async {
                await d.newToken();
                setState(() {});
                showMessage(l.screensNewLinksDone, tone: MessageTone.success);
              },
              child: Text(l.screensNewLinks),
            ),
          FilledButton(onPressed: () => goBack<void>(), child: Text(l.commonDone)),
        ]),
      ],
    );
  }
}
