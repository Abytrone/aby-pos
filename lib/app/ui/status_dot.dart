import 'package:flutter/material.dart';

import '../services/status_service.dart';
import '../theme/aby_colors.dart';

/// Status colour. Never lime: lime is kept for the waiting-to-sync dot.
Color statusColor(StatusLevel level, AbyColors c) => switch (level) {
      StatusLevel.ok => c.success,
      StatusLevel.info => c.blue,
      StatusLevel.warning => c.warning,
      StatusLevel.problem => c.danger,
    };

class StatusDot extends StatelessWidget {
  const StatusDot({super.key, required this.level, this.size = 10, this.pulse = false});

  final StatusLevel level;
  final double size;

  /// Breathes while something is happening (a backup being written).
  final bool pulse;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final dot = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: statusColor(level, c), shape: BoxShape.circle),
    );
    return pulse ? _Pulse(child: dot) : dot;
  }
}

class _Pulse extends StatefulWidget {
  const _Pulse({required this.child});

  final Widget child;

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: Tween(begin: 0.3, end: 1.0).animate(_controller),
        child: ScaleTransition(scale: Tween(begin: 0.8, end: 1.15).animate(_controller), child: widget.child),
      );
}
