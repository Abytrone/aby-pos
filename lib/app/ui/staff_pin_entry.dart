import 'package:flutter/material.dart';

import '../data/repositories/staff_repository.dart';
import 'l10n.dart';
import 'pin_pad.dart';

/// Staff number, then PIN, on one keypad. No names anywhere: the number
/// says who, the PIN proves it, so nobody learns who works here and two
/// people may share a PIN.
///
/// [onSubmit] gets the number (null when [knownPerson], e.g. after a badge
/// scan) and the PIN, and returns an error message or null when accepted.
/// After a wrong try the number stays, with a link to change it.
class StaffPinEntry extends StatefulWidget {
  const StaffPinEntry({
    super.key,
    required this.onSubmit,
    this.numberTitle,
    this.pinTitle,
    this.knownPerson = false,
  });

  final Future<String?> Function(String? number, String pin) onSubmit;
  final String? numberTitle;
  final String? pinTitle;

  /// Who it is is already known: straight to the PIN.
  final bool knownPerson;

  @override
  State<StaffPinEntry> createState() => _StaffPinEntryState();
}

class _StaffPinEntryState extends State<StaffPinEntry> {
  String? _number;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final number = _number;
    if (number == null && !widget.knownPerson) {
      return PinPad(
        key: const ValueKey('staff-number'),
        title: widget.numberTitle ?? l.staffNumberTitle,
        length: StaffRepository.numberLength,
        reveal: true,
        onSubmit: (typed) async {
          setState(() => _number = typed);
          return null;
        },
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PinPad(
          key: ValueKey('pin-$number'),
          title: widget.pinTitle ?? l.signInPinTitle,
          onSubmit: (pin) => widget.onSubmit(number, pin),
        ),
        if (number != null)
          TextButton(
            onPressed: () => setState(() => _number = null),
            child: Text(l.staffNumberChange(number)),
          ),
      ],
    );
  }
}
