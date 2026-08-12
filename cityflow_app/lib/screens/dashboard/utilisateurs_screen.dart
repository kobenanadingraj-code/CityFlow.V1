import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Écran 'Utilisateurs' du dashboard web (présent dans la maquette Figma).
/// Le backend accounts/ n'expose pour l'instant que des endpoints
/// self-service ('/api/auth/me/...') — il n'y a pas encore de vue liste
/// des utilisateurs réservée aux autorités (GET /api/auth/users/ ou
/// équivalent, avec pagination + recherche). Cet écran reste un espace
/// réservé explicite tant que cet endpoint n'est pas ajouté côté API,
/// plutôt que d'afficher des données inventées.
class UtilisateursScreen extends StatelessWidget {
  const UtilisateursScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Utilisateurs', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Gestion des comptes citoyens et autorités.', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.people_outline_rounded, size: 48, color: AppColors.textMuted),
                  const SizedBox(height: 12),
                  const Text('Fonctionnalité à venir', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 60),
                    child: Text(
                      'Le backend ne fournit pas encore d\'endpoint de liste des utilisateurs réservé aux autorités. '
                      'Il faudra l\'ajouter dans accounts/ (vue + permission IsAutorite) avant de pouvoir brancher cet écran.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
