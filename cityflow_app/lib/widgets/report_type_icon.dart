import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Icône colorée par type de signalement/alerte — réutilisée sur Accueil,
/// Alertes, et les listes du dashboard web.
class ReportTypeIcon extends StatelessWidget {
  final String type;
  final double size;

  const ReportTypeIcon({super.key, required this.type, this.size = 40});

  IconData get _icon {
    switch (type) {
      case 'accident':
        return Icons.error_rounded;
      case 'embouteillage':
        return Icons.traffic_rounded;
      case 'inondation':
        return Icons.water_drop_rounded;
      case 'travaux':
        return Icons.construction_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = AppColors.typeColor(type);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
      child: Icon(_icon, color: color, size: size * 0.55),
    );
  }
}
