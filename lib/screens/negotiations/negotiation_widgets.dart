import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/negotiation.dart';
import '../../widgets/common.dart';

Color negotiationColor(BuildContext context, NegotiationStatus s) => switch (s) {
      NegotiationStatus.aberta => context.palette.info,
      NegotiationStatus.aceita => context.palette.success,
      NegotiationStatus.recusada => context.palette.danger,
      NegotiationStatus.cancelada => context.palette.muted,
    };

class NegotiationStatusBadge extends StatelessWidget {
  const NegotiationStatusBadge({super.key, required this.status});

  final NegotiationStatus status;

  @override
  Widget build(BuildContext context) =>
      StatusBadge(label: status.label, color: negotiationColor(context, status));
}
