import 'package:flutter/material.dart';

import '../../models/mobility.dart';
import '../../services/weather_service.dart';
import '../../theme/app_theme.dart';

/// Écran 'Alertes' du dashboard web — segments à risque d'inondation
/// actuellement sous alerte météo (WeatherAlertsView : zone_inondable=True
/// + WeatherEvent actif non 'normal' sur la même zone).
class AlertsManagementScreen extends StatefulWidget {
  const AlertsManagementScreen({super.key});

  @override
  State<AlertsManagementScreen> createState() => _AlertsManagementScreenState();
}

class _AlertsManagementScreenState extends State<AlertsManagementScreen> {
  final _service = WeatherService();
  List<RoadSegment> _segments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final segments = await _service.alerts();
      if (!mounted) return;
      setState(() => _segments = segments);
    } catch (_) {
      // liste vide en cas d'échec réseau
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Alertes', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Segments inondables actuellement sous alerte météo (pluie modérée/forte, orage).',
                      style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
              OutlinedButton.icon(onPressed: _load, icon: const Icon(Icons.refresh_rounded, size: 16), label: const Text('Actualiser')),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _segments.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.check_circle_outline_rounded, color: AppColors.success),
                            SizedBox(width: 12),
                            Expanded(child: Text('Aucune alerte active pour le moment — toutes les zones inondables sont sous surveillance normale.')),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: _segments.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final s = _segments[i];
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.inondation.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40, height: 40,
                                  decoration: BoxDecoration(color: AppColors.inondation.withValues(alpha: 0.12), shape: BoxShape.circle),
                                  child: const Icon(Icons.water_drop_rounded, color: AppColors.inondation, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(s.nom, style: const TextStyle(fontWeight: FontWeight.w600)),
                                      Text(s.zone, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: AppColors.inondation.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                                  child: const Text('Risque inondation', style: TextStyle(color: AppColors.inondation, fontSize: 12, fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
