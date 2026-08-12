import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

/// Écran 'Paramètres' du dashboard web. Le backend n'expose pas encore de
/// réglages spécifiques aux autorités (rôles, seuils d'alerte, etc.) — cet
/// écran affiche pour l'instant le compte connecté et laisse la place aux
/// futurs réglages une fois les endpoints correspondants ajoutés côté API.
class ParametresScreen extends StatelessWidget {
  const ParametresScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Paramètres', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Compte et informations de l\'autorité connectée.', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(radius: 22, backgroundColor: AppColors.primary, child: Icon(Icons.person, color: Colors.white)),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.nomComplet ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        Text(user?.email ?? '', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Row(children: const [
                  Icon(Icons.badge_outlined, size: 18, color: AppColors.textMuted),
                  SizedBox(width: 10),
                  Text('Rôle : Autorité'),
                ]),
                const SizedBox(height: 8),
                if (user?.zone.isNotEmpty == true)
                  Row(children: [
                    const Icon(Icons.location_on_outlined, size: 18, color: AppColors.textMuted),
                    const SizedBox(width: 10),
                    Text('Zone : ${user!.zone}'),
                  ]),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, color: AppColors.textMuted, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'D\'autres réglages (gestion des rôles, seuils d\'alerte, notifications d\'équipe) pourront être ajoutés ici une fois les endpoints correspondants créés côté API.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
