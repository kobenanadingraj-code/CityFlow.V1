import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/profile_service.dart';
import '../theme/app_theme.dart';

/// Écran Préférences — accessible depuis Profil.
class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  final _service = ProfileService();
  UserPreferences? _prefs;
  bool _loading = true;
  bool _saving = false;

  static const _modes = {
    'voiture': 'Voiture',
    'moto': 'Moto',
    'a_pied': 'À pied',
    'transport_commun': 'Transport en commun',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final prefs = await _service.getPreferences();
      if (!mounted) return;
      setState(() => _prefs = prefs);
    } catch (_) {
      // valeurs par défaut si l'appel échoue
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _update(UserPreferences updated) async {
    setState(() {
      _prefs = updated;
      _saving = true;
    });
    try {
      await _service.updatePreferences(updated);
    } catch (_) {
      // on garde l'état local même si la sauvegarde échoue silencieusement
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prefs = _prefs;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Préférences'),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))),
            ),
        ],
      ),
      body: _loading || prefs == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Notifications actives'),
                  subtitle: const Text('Alertes trafic, météo et signalements', style: TextStyle(fontSize: 12)),
                  value: prefs.notificationsActives,
                  activeColor: AppColors.primary,
                  onChanged: (v) => _update(UserPreferences(
                    notificationsActives: v,
                    modeTransport: prefs.modeTransport,
                    eviterZonesInondables: prefs.eviterZonesInondables,
                    eviterPeages: prefs.eviterPeages,
                  )),
                ),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('Mode de transport', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _modes.entries.map((e) {
                    final selected = e.key == prefs.modeTransport;
                    return ChoiceChip(
                      label: Text(e.value),
                      selected: selected,
                      onSelected: (_) => _update(UserPreferences(
                        notificationsActives: prefs.notificationsActives,
                        modeTransport: e.key,
                        eviterZonesInondables: prefs.eviterZonesInondables,
                        eviterPeages: prefs.eviterPeages,
                      )),
                      selectedColor: AppColors.primary.withValues(alpha: 0.12),
                      labelStyle: TextStyle(color: selected ? AppColors.primary : AppColors.textPrimary),
                    );
                  }).toList(),
                ),
                const Divider(height: 32),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Éviter les zones inondables'),
                  value: prefs.eviterZonesInondables,
                  activeColor: AppColors.primary,
                  onChanged: (v) => _update(UserPreferences(
                    notificationsActives: prefs.notificationsActives,
                    modeTransport: prefs.modeTransport,
                    eviterZonesInondables: v,
                    eviterPeages: prefs.eviterPeages,
                  )),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Éviter les péages'),
                  value: prefs.eviterPeages,
                  activeColor: AppColors.primary,
                  onChanged: (v) => _update(UserPreferences(
                    notificationsActives: prefs.notificationsActives,
                    modeTransport: prefs.modeTransport,
                    eviterZonesInondables: prefs.eviterZonesInondables,
                    eviterPeages: v,
                  )),
                ),
              ],
            ),
    );
  }
}
