import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../models/dashboard.dart';
import '../../models/report.dart';
import '../../services/dashboard_service.dart';
import '../../services/reports_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/report_type_icon.dart';

const _abidjanCenter = LatLng(5.3097, -4.0125);

/// Écran 9 — Tableau de bord (dashboard web, autorités).
class DashboardHomeScreen extends StatefulWidget {
  const DashboardHomeScreen({super.key});

  @override
  State<DashboardHomeScreen> createState() => _DashboardHomeScreenState();
}

class _DashboardHomeScreenState extends State<DashboardHomeScreen> {
  final _dashboardService = DashboardService();
  final _reportsService = ReportsService();

  DashboardStats? _stats;
  RepartitionParType? _repartition;
  List<ActivityLogEntry> _activite = [];
  List<IncidentCarte> _incidents = [];
  List<Report> _incidentsRecents = [];
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
        _dashboardService.stats(),
        _dashboardService.repartitionParType(),
        _dashboardService.activiteRecente(limit: 6),
        _dashboardService.incidentsCarte(),
        _reportsService.list(pageSize: 5),
      ]);
      if (!mounted) return;
      setState(() {
        _stats = results[0] as DashboardStats;
        _repartition = results[1] as RepartitionParType;
        _activite = results[2] as List<ActivityLogEntry>;
        _incidents = results[3] as List<IncidentCarte>;
        _incidentsRecents = results[4] as List<Report>;
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
          const Text('Tableau de bord', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Vue d\'ensemble en temps réel de la mobilité à Abidjan', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth >= 900 ? 4 : (constraints.maxWidth >= 560 ? 2 : 1);
              final stats = _stats;
              final cards = [
                _KpiCard(label: 'Signalements aujourd\'hui', kpi: stats?.signalementsAujourdhui, icon: Icons.campaign_rounded, color: AppColors.primary),
                _KpiCard(label: 'Incidents actifs', kpi: stats?.incidentsActifs, icon: Icons.warning_amber_rounded, color: AppColors.accident),
                _KpiCard(label: 'Zones à risque', kpi: stats?.zonesARisque, icon: Icons.location_on_rounded, color: AppColors.embouteillage),
                _KpiCard(label: 'Utilisateurs actifs', kpi: stats?.utilisateursActifs, icon: Icons.people_alt_rounded, color: AppColors.success),
              ];
              return GridView.count(
                crossAxisCount: cols,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 2.1,
                children: cards,
              );
            },
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 900;

              final incidentsRecents = _PanelCard(
                title: 'Incidents récents',
                trailing: TextButton(
                  onPressed: () {},
                  child: const Text('Voir tous les incidents'),
                ),
                child: _incidentsRecents.isEmpty
                    ? const Padding(padding: EdgeInsets.all(16), child: Text('Aucun incident récent.', style: TextStyle(color: AppColors.textSecondary)))
                    : Column(
                        children: _incidentsRecents.map((r) => _IncidentRecentTile(report: r)).toList(),
                      ),
              );

              final carte = _PanelCard(
                title: 'Carte des incidents — Abidjan',
                child: Column(
                  children: [
                    SizedBox(
                      height: 240,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: FlutterMap(
                          options: const MapOptions(initialCenter: _abidjanCenter, initialZoom: 11.5),
                          children: [
                            TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.cityflow.app'),
                            MarkerLayer(
                              markers: _incidents
                                  .map((i) => Marker(
                                        point: LatLng(i.latitude, i.longitude),
                                        width: 22,
                                        height: 22,
                                        child: Container(
                                          decoration: BoxDecoration(color: AppColors.typeColor(i.type), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 16,
                      runSpacing: 6,
                      children: const [
                        _LegendDot(color: AppColors.accident, label: 'Accident'),
                        _LegendDot(color: AppColors.embouteillage, label: 'Embouteillage'),
                        _LegendDot(color: AppColors.inondation, label: 'Risque inondation'),
                        _LegendDot(color: AppColors.travaux, label: 'Travaux'),
                        _LegendDot(color: AppColors.textMuted, label: 'Autres'),
                      ],
                    ),
                  ],
                ),
              );

              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [Expanded(flex: 4, child: incidentsRecents), const SizedBox(width: 16), Expanded(flex: 5, child: carte)],
                );
              }
              return Column(children: [incidentsRecents, const SizedBox(height: 16), carte]);
            },
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 1100;

              final repartitionPanel = _PanelCard(
                title: 'Répartition des incidents',
                child: _repartition == null || _repartition!.repartition.isEmpty
                    ? const Padding(padding: EdgeInsets.all(24), child: Text('Aucune donnée.', style: TextStyle(color: AppColors.textSecondary)))
                    : SizedBox(
                        height: 200,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            PieChart(PieChartData(
                              sectionsSpace: 2,
                              centerSpaceRadius: 44,
                              sections: _repartition!.repartition
                                  .map((r) => PieChartSectionData(
                                        value: r.total.toDouble(),
                                        color: AppColors.typeColor(r.type),
                                        showTitle: false,
                                        radius: 34,
                                      ))
                                  .toList(),
                            )),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('${_repartition!.total}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                const Text('Total', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              ],
                            ),
                          ],
                        ),
                      ),
                trailingBelow: _repartition == null
                    ? null
                    : Column(
                        children: _repartition!.repartition
                            .map((r) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 3),
                                  child: Row(
                                    children: [
                                      Container(width: 8, height: 8, decoration: BoxDecoration(color: AppColors.typeColor(r.type), shape: BoxShape.circle)),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text(r.type, style: const TextStyle(fontSize: 12))),
                                      Text('${r.total} (${r.pourcentage.toStringAsFixed(1)}%)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ))
                            .toList(),
                      ),
              );

              final barsPanel = _PanelCard(
                title: 'Incidents par type',
                child: _repartition == null || _repartition!.repartition.isEmpty
                    ? const Padding(padding: EdgeInsets.all(24), child: Text('Aucune donnée.', style: TextStyle(color: AppColors.textSecondary)))
                    : Column(
                        children: _repartition!.repartition.map((r) {
                          final maxTotal = _repartition!.repartition.map((e) => e.total).reduce((a, b) => a > b ? a : b);
                          final ratio = maxTotal == 0 ? 0.0 : r.total / maxTotal;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                SizedBox(width: 90, child: Text(r.type, style: const TextStyle(fontSize: 12))),
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: ratio,
                                      minHeight: 10,
                                      backgroundColor: AppColors.background,
                                      color: AppColors.typeColor(r.type),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                SizedBox(width: 26, child: Text('${r.total}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
              );

              final activitePanel = _PanelCard(
                title: 'Activité récente',
                child: _activite.isEmpty
                    ? const Padding(padding: EdgeInsets.all(16), child: Text('Aucune activité récente.', style: TextStyle(color: AppColors.textSecondary)))
                    : Column(children: _activite.map((a) => _ActiviteTile(entry: a)).toList()),
              );

              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: repartitionPanel),
                    const SizedBox(width: 16),
                    Expanded(child: barsPanel),
                    const SizedBox(width: 16),
                    Expanded(child: activitePanel),
                  ],
                );
              }
              return Column(children: [repartitionPanel, const SizedBox(height: 16), barsPanel, const SizedBox(height: 16), activitePanel]);
            },
          ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final KpiValue? kpi;
  final IconData icon;
  final Color color;

  const _KpiCard({required this.label, required this.kpi, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final variation = kpi?.variationPct;
    final positive = (variation ?? 0) >= 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('${kpi?.valeur ?? '—'}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    if (variation != null) ...[
                      const SizedBox(width: 8),
                      Icon(positive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                          size: 13, color: positive ? AppColors.success : AppColors.accident),
                      Text('${variation.abs().toStringAsFixed(0)}%',
                          style: TextStyle(fontSize: 11, color: positive ? AppColors.success : AppColors.accident)),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;
  final Widget? trailingBelow;
  const _PanelCard({required this.title, required this.child, this.trailing, this.trailingBelow});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          child,
          if (trailingBelow != null) ...[const SizedBox(height: 8), trailingBelow!],
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _IncidentRecentTile extends StatelessWidget {
  final Report report;
  const _IncidentRecentTile({required this.report});

  Color get _prioriteColor {
    switch (report.priorite) {
      case 'elevee':
        return AppColors.accident;
      case 'moyenne':
        return AppColors.embouteillage;
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          ReportTypeIcon(type: report.type, size: 34),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(report.typeLabel, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Text(report.zone, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: _prioriteColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                child: Text(report.prioriteLabel, style: TextStyle(color: _prioriteColor, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 4),
              Text(report.ilYA, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActiviteTile extends StatelessWidget {
  final ActivityLogEntry entry;
  const _ActiviteTile({required this.entry});

  static const _titres = {
    'signalement_cree': 'Nouveau signalement ajouté',
    'utilisateur_inscrit': 'Utilisateur inscrit',
    'alerte_declenchee': 'Alerte déclenchée',
    'incident_resolu': 'Incident résolu',
  };

  ({IconData icon, Color color}) get _visuel {
    switch (entry.type) {
      case 'signalement_cree':
        return (icon: Icons.add_circle_rounded, color: AppColors.success);
      case 'utilisateur_inscrit':
        return (icon: Icons.person_rounded, color: AppColors.primary);
      case 'alerte_declenchee':
        return (icon: Icons.warning_rounded, color: AppColors.embouteillage);
      case 'incident_resolu':
        return (icon: Icons.check_circle_rounded, color: AppColors.success);
      default:
        return (icon: Icons.circle, color: AppColors.textMuted);
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = _visuel;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(v.icon, size: 18, color: v.color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_titres[entry.type] ?? entry.type, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                Text(entry.description, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                Text(entry.ilYA, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
