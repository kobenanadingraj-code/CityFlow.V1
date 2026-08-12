import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../theme/app_theme.dart';
import 'auth/welcome_screen.dart';
import 'favorites_screen.dart';
import 'notifications_screen.dart';
import 'preferences_screen.dart';
import 'zones_surveillees_screen.dart';

/// Écran 8 — Profil.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _profileService = ProfileService();
  UserPreferences? _prefs;

  @override
  void initState() {
    super.initState();
    _profileService.getPreferences().then((p) {
      if (mounted) setState(() => _prefs = p);
    }).catchError((_) {});
  }

  Future<void> _toggleNotifications(bool value) async {
    final prefs = _prefs;
    if (prefs == null) return;
    final updated = UserPreferences(
      notificationsActives: value,
      modeTransport: prefs.modeTransport,
      eviterZonesInondables: prefs.eviterZonesInondables,
      eviterPeages: prefs.eviterPeages,
    );
    setState(() => _prefs = updated);
    try {
      await _profileService.updatePreferences(updated);
    } catch (_) {
      // on garde l'état local même si la sauvegarde échoue silencieusement
    }
  }

  Future<void> _modifierProfil(BuildContext context, AppUser user) async {
    final nomCtrl = TextEditingController(text: user.nomComplet);
    final telCtrl = TextEditingController(text: user.telephone ?? '');
    final adresseCtrl = TextEditingController(text: user.adresse);

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Modifier le profil', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(controller: nomCtrl, decoration: const InputDecoration(labelText: 'Nom complet')),
              const SizedBox(height: 10),
              TextField(controller: telCtrl, decoration: const InputDecoration(labelText: 'Téléphone')),
              const SizedBox(height: 10),
              TextField(controller: adresseCtrl, decoration: const InputDecoration(labelText: 'Adresse')),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await context.read<AuthService>().updateProfile({
                      'nom_complet': nomCtrl.text.trim(),
                      'telephone': telCtrl.text.trim(),
                      'adresse': adresseCtrl.text.trim(),
                    });
                    if (context.mounted) Navigator.of(context).pop(true);
                  } on ApiException catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
                    }
                  }
                },
                child: const Text('Enregistrer'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
    if (saved == true) setState(() {});
  }

  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Déconnexion')),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    await context.read<AuthService>().logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }

  void _showInfoScreen(BuildContext context, String titre, String contenu) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: Text(titre)),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(contenu, style: const TextStyle(color: AppColors.textSecondary, height: 1.5)),
        ),
      ),
    ));
  }

  String _initiales(String nomComplet) {
    final parts = nomComplet.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Profil', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    SizedBox(height: 2),
                    Text('Gérez vos informations et préférences', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.notifications_none_rounded, size: 24),
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                ),
              ],
            ),
            const SizedBox(height: 12),
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: user == null ? null : () => _modifierProfil(context, user),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primary,
                      child: Text(_initiales(user?.nomComplet ?? ''), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user?.nomComplet ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          Text(user?.email ?? '', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Mes lieux enregistrés', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                TextButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FavoritesScreen())),
                  child: const Text('Voir tout'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _LieuChip(icon: Icons.home_rounded, label: 'Maison', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FavoritesScreen())))),
                const SizedBox(width: 8),
                Expanded(child: _LieuChip(icon: Icons.work_rounded, label: 'Travail', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FavoritesScreen())))),
                const SizedBox(width: 8),
                Expanded(child: _LieuChip(icon: Icons.star_rounded, label: 'Favoris', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FavoritesScreen())))),
                const SizedBox(width: 8),
                Expanded(child: _LieuChip(icon: Icons.more_horiz_rounded, label: 'Autres', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FavoritesScreen())))),
              ],
            ),
            const SizedBox(height: 24),
            const _SectionHeader('Informations personnelles'),
            _InfoRow(icon: Icons.mail_outline_rounded, label: user?.email ?? '', onTap: user == null ? null : () => _modifierProfil(context, user)),
            _InfoRow(icon: Icons.phone_outlined, label: user?.telephone?.isNotEmpty == true ? user!.telephone! : 'Non renseigné', onTap: user == null ? null : () => _modifierProfil(context, user)),
            _InfoRow(icon: Icons.location_on_outlined, label: user?.adresse.isNotEmpty == true ? user!.adresse : 'Non renseignée', onTap: user == null ? null : () => _modifierProfil(context, user)),
            const SizedBox(height: 20),
            const _SectionHeader('Préférences'),
            _ToggleRow(
              icon: Icons.notifications_none_rounded,
              label: 'Notifications',
              value: _prefs?.notificationsActives ?? true,
              onChanged: _prefs == null ? null : _toggleNotifications,
            ),
            _MenuRow(icon: Icons.location_on_outlined, label: 'Zones à surveiller', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ZonesSurveilleesScreen()))),
            _MenuRow(icon: Icons.star_outline_rounded, label: 'Itinéraires favoris', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FavoritesScreen()))),
            _MenuRow(
              icon: Icons.tune_rounded,
              label: 'Préférences de trajet',
              sousTitre: 'Mode de transport, zones inondables, péages',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PreferencesScreen())),
            ),
            const SizedBox(height: 20),
            const _SectionHeader('Autres'),
            _MenuRow(
              icon: Icons.help_outline_rounded,
              label: 'Aide et support',
              onTap: () => _showInfoScreen(context, 'Aide et support',
                  "Pour toute question sur l'utilisation de CityFlow AI, contacte l'équipe via l'adresse indiquée dans l'écran À propos. Une FAQ détaillée pourra être ajoutée ici."),
            ),
            _MenuRow(
              icon: Icons.privacy_tip_outlined,
              label: 'Confidentialité et sécurité',
              onTap: () => _showInfoScreen(context, 'Confidentialité et sécurité',
                  'Tes données (signalements, lieux enregistrés, préférences) sont utilisées uniquement pour améliorer les prédictions de trafic et te proposer des itinéraires personnalisés. Elles ne sont jamais revendues à des tiers.'),
            ),
            _MenuRow(
              icon: Icons.info_outline_rounded,
              label: 'À propos de CityFlow',
              sousTitre: 'v1.0',
              onTap: () => _showInfoScreen(context, 'À propos de CityFlow AI',
                  'CityFlow AI — prédiction de congestion pour Abidjan.\nVersion 1.0.\nDéplacez-vous intelligent, arrivez en toute sérénité.'),
            ),
            const SizedBox(height: 8),
            _MenuRow(icon: Icons.logout_rounded, label: 'Se déconnecter', color: AppColors.accident, onTap: () => _logout(context)),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textSecondary)),
    );
  }
}

class _LieuChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _LieuChip({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
        child: Column(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _InfoRow({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.textMuted),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
            const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? sousTitre;
  final VoidCallback onTap;
  final Color? color;
  const _MenuRow({required this.icon, required this.label, this.sousTitre, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textPrimary;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color ?? AppColors.textMuted),
            const SizedBox(width: 12),
            Expanded(
              child: sousTitre == null
                  ? Text(label, style: TextStyle(fontSize: 13, color: c))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label, style: TextStyle(fontSize: 13, color: c)),
                        Text(sousTitre!, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
            ),
            if (color == null) const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;
  const _ToggleRow({required this.icon, required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
          Switch(value: value, activeColor: AppColors.success, onChanged: onChanged),
        ],
      ),
    );
  }
}
