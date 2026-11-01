import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'l10n.dart';

/// A search box for a list whose controller keeps the search in [query].
/// The box takes its text from the query, so coming back to a screen shows
/// the search still in force, never an empty box over a filtered list, and
/// the x clears both.
class QueryField extends StatefulWidget {
  const QueryField({super.key, required this.query, required this.hint});

  final RxString query;
  final String hint;

  @override
  State<QueryField> createState() => _QueryFieldState();
}

class _QueryFieldState extends State<QueryField> {
  late final _text = TextEditingController(text: widget.query.value);
  // The query can change without the box: a reset, or another screen.
  late final Worker _follow = ever<String>(widget.query, (v) {
    if (v != _text.text) _text.text = v;
  });

  @override
  void initState() {
    super.initState();
    _follow;
  }

  @override
  void dispose() {
    _follow.dispose();
    _text.dispose();
    super.dispose();
  }

  void _clear() {
    _text.clear();
    widget.query.value = '';
  }

  @override
  Widget build(BuildContext context) => TextField(
        controller: _text,
        onChanged: (v) => widget.query.value = v,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: _text,
            builder: (_, value, _) => value.text.isEmpty
                ? const SizedBox.shrink()
                : IconButton(tooltip: context.l10n.commonClear, icon: const Icon(Icons.close), onPressed: _clear),
          ),
          hintText: widget.hint,
          isDense: true,
        ),
      );
}
