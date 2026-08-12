import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/profile_service.dart';
import '../theme/app_theme.dart';

/// Écran Zones surveillées — l'utilisateur reçoit une notification dès
/// qu'un signalement ou une alerte météo touche une de ces zones
/// (voir reports/signals.py et environment/signals.py côté backend).
class ZonesSurveilleesScreen extends StatefulWidget {
  const ZonesSurveilleesScreen({super.key});

  @override
  State<ZonesSurveilleesScreen> createState() => _ZonesSurveilleesScreenState();
}

class _ZonesSurveilleesScreenState extends State<ZonesSurveilleesScreen> {
  final _service = ProfileService();
  final _zoneCtrl = TextEditingController();
  List<ZoneSurveillee> _zones = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _zoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final zones = await _service.getZonesSurveillees();
      if (!mounted) return;
      setState(() => _zones = zones);
    } catch (_) {
      // liste vide en cas d'échec réseau
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _add() async {
    final zone = _zoneCtrl.text.trim();
    if (zone.isEmpty) return;
    await _service.addZoneSurveillee(zone);
    _zoneCtrl.clear();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Zones surveillées')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _zoneCtrl,
                      decoration: const InputDecoration(hintText: 'Ex : Yopougon'),
                      onSubmitted: (_) => _add(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(onPressed: _add, child: const Text('Ajouter')),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _zones.isEmpty
                      ? const Center(
                          child: Text('Aucune zone surveillée.', style: TextStyle(color: AppColors.textSecondary)),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _zones.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, i) {
                            final z = _zones[i];
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.location_on_outlined, color: AppColors.primary, size: 18),
                                  const SizedBox(width: 10),
                                  Expanded(child: Text(z.zone)),
                                  IconButton(
                                    icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
                                    onPressed: () async {
                                      await _service.deleteZoneSurveillee(z.id);
                                      _load();
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
