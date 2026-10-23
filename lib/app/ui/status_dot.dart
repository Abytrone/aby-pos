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
  const StatusDot({super.key, required this.level, this.size = 10});

  final StatusLevel level;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: statusColor(level, c), shape: BoxShape.circle),
    );
  }
}
