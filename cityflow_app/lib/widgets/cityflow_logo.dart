import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_theme.dart';

/// Icône du logo CityFlow AI — charge le vrai SVG (pin blanc sur dégradé
/// violet→vert, reconstruit d'après les captures de la maquette fournies
/// par l'utilisateur : assets/images/logo_cityflow.svg). Une ombre portée
/// légère est ajoutée en plus, comme sur les écrans Splash/Bienvenue.
class CityFlowLogo extends StatelessWidget {
  final double size;

  const CityFlowLogo({super.key, this.size = 64});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: AppColors.primary.withValues(alpha: 0.25), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: SvgPicture.asset('assets/images/logo_cityflow.svg', width: size, height: size),
    );
  }
}
