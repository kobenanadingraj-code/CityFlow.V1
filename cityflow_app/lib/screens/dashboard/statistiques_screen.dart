import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../models/dashboard.dart';
import '../../models/mobility.dart';
import '../../services/dashboard_service.dart';
import '../../services/mobility_service.dart';
import '../../theme/app_theme.dart';

/// Écran 'Statistiques' du dashboard web — heures de pointe, zones à risque
/// et répartition par type sur l'ensemble d'Abidjan (mobility/aggregation.py
/// + dashboard/repartition-par-type).
class StatistiquesScreen extends StatefulWidget {
  const StatistiquesScreen({super.key});

  @override
  State<StatistiquesScreen> createState() => _StatistiquesScreenState();
}

class _StatistiquesScreenState extends State<StatistiquesScreen> {
  final _mobilityService = MobilityService();
  final _dashboardService = DashboardService();

  CartePrevisions? _previsions;
  RepartitionParType? _repartition;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _mobilityService.previsions(),
        _dashboardService.repartitionParType(),
      ]);
      if (!mounted) return;
      setState(() {
        _previsions = results[0] as CartePrevisions;
        _repartition = results[1] as RepartitionParType;
      });
    } catch (_) {
      // écran reste utilisable même en cas d'échec partiel
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('Statistiques', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Tendances de congestion à l\'échelle d\'Abidjan.', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Heures de pointe (moyenne toutes zones)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 16),
                if (_previsions == null || _previsions!.heuresDePointe.isEmpty)
                  const Text('Données indisponibles.', style: TextStyle(color: AppColors.textSecondary))
                else
                  SizedBox(
                    height: 180,
                    child: BarChart(BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: 100,
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final i = value.toInt();
                              if (i < 0 || i >= _previsions!.heuresDePointe.length) return const SizedBox();
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(_previsions!.heuresDePointe[i].heure, style: const TextStyle(fontSize: 11)),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: const FlGridData(show: false),
                      barGroups: [
                        for (var i = 0; i < _previsions!.heuresDePointe.length; i++)
                          BarChartGroupData(x: i, barRods: [
                            BarChartRodData(
                              toY: _previsions!.heuresDePointe[i].scoreMoyen.toDouble(),
                              color: AppColors.trafficColor(_previsions!.heuresDePointe[i].niveau),
                              width: 28,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ]),
                      ],
                    )),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Zones à risque', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 12),
                if (_previsions == null || _previsions!.zonesARisque.isEmpty)
                  const Text('Aucune zone à risque signalée.', style: TextStyle(color: AppColors.textSecondary))
                else
                  ..._previsions!.zonesARisque.map((z) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Container(width: 8, height: 8, decoration: BoxDecoration(color: AppColors.trafficColor(z.niveau), shape: BoxShape.circle)),
                            const SizedBox(width: 10),
                            Expanded(child: Text('${z.zone} · ${z.creneau}')),
                            Text('${z.scoreMoyen} · ${z.niveau}', style: TextStyle(color: AppColors.trafficColor(z.niveau), fontWeight: FontWeight.w600)),
                          ],
                        ),
                      )),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Répartition des signalements par type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 12),
                if (_repartition == null || _repartition!.repartition.isEmpty)
                  const Text('Aucune donnée.', style: TextStyle(color: AppColors.textSecondary))
                else
                  ..._repartition!.repartition.map((r) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Container(width: 8, height: 8, decoration: BoxDecoration(color: AppColors.typeColor(r.type), shape: BoxShape.circle)),
                            const SizedBox(width: 10),
                            Expanded(child: Text(r.type)),
                            Text('${r.total} (${r.pourcentage.toStringAsFixed(1)}%)', style: const TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
