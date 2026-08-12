import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/itineraire.dart';
import '../models/mobility.dart';
import '../models/report.dart';
import '../services/conseil_service.dart';
import '../services/mobility_service.dart';
import '../services/reports_service.dart';
import '../services/weather_service.dart';
import '../theme/app_theme.dart';
import '../widgets/report_type_icon.dart';
import 'notifications_screen.dart';

const _abidjanCenter = LatLng(5.3097, -4.0125);

/// Écran 5 — Carte : 4 onglets (Trafic en direct / Prédictions / Incidents /
/// Zones inondables), à l'image de la maquette.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 4, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('CityFlow AI', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.notifications_none_rounded),
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                  ),
                ],
              ),
            ),
            TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textMuted,
              indicatorColor: AppColors.primary,
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              tabs: const [
                Tab(icon: Icon(Icons.bar_chart_rounded, size: 18), text: 'Trafic en direct'),
                Tab(icon: Icon(Icons.trending_up_rounded, size: 18), text: 'Prédictions'),
                Tab(icon: Icon(Icons.warning_amber_rounded, size: 18), text: 'Incidents'),
                Tab(icon: Icon(Icons.water_drop_outlined, size: 18), text: 'Zones inondables'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  _TraficDirectTab(),
                  _PredictionsTab(),
                  _IncidentsTab(),
                  _ZonesInondablesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BaseMap extends StatelessWidget {
  final List<Marker> markers;
  final double height;
  const _BaseMap({required this.markers, this.height = 220});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: height,
        child: FlutterMap(
          options: const MapOptions(initialCenter: _abidjanCenter, initialZoom: 12),
          children: [
            TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.cityflow.app'),
            MarkerLayer(markers: markers),
          ],
        ),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 4,
      children: const [
        _Dot(color: AppColors.trafficFluide, label: 'Fluide'),
        _Dot(color: AppColors.trafficModere, label: 'Modéré'),
        _Dot(color: AppColors.trafficDense, label: 'Dense'),
        _Dot(color: AppColors.trafficTresDense, label: 'Très dense'),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  final String label;
  const _Dot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}

/// Onglet 'Trafic en direct' — segments récemment signalés, positionnés sur
/// la carte. RoadSegment ne stocke qu'un point (pas de tracé de route), donc
/// la représentation reste par marqueurs et non par routes colorées.
class _TraficDirectTab extends StatefulWidget {
  const _TraficDirectTab();

  @override
  State<_TraficDirectTab> createState() => _TraficDirectTabState();
}

class _TraficDirectTabState extends State<_TraficDirectTab> {
  final _service = ReportsService();
  List<Report> _reports = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _service.list(pageSize: 40).then((r) {
      if (mounted) setState(() {
        _reports = r.where((e) => e.latitude != null && e.longitude != null).toList();
        _loading = false;
      });
    }).catchError((_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (_loading) const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
        _BaseMap(
          height: 320,
          markers: _reports
              .map((r) => Marker(
                    point: LatLng(r.latitude!, r.longitude!),
                    width: 30,
                    height: 30,
                    child: ReportTypeIcon(type: r.type, size: 30),
                  ))
              .toList(),
        ),
        const SizedBox(height: 12),
        const _LegendRow(),
      ],
    );
  }
}

/// Onglet 'Prédictions' — heures de pointe + zones à risque + itinéraires
/// recommandés (mobility/aggregation.py + conseil/itineraires-recommandes).
class _PredictionsTab extends StatefulWidget {
  const _PredictionsTab();

  @override
  State<_PredictionsTab> createState() => _PredictionsTabState();
}

class _PredictionsTabState extends State<_PredictionsTab> {
  final _mobilityService = MobilityService();
  final _conseilService = ConseilService();

  CartePrevisions? _previsions;
  List<ItineraireRecommande> _recommandes = [];
  int _creneauSelectionne = 0;
  String _periode = 'Aujourd\'hui';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([_mobilityService.previsions(), _conseilService.itinerairesRecommandes()]);
      if (!mounted) return;
      setState(() {
        _previsions = results[0] as CartePrevisions;
        _recommandes = results[1] as List<ItineraireRecommande>;
      });
    } catch (_) {
      // écran reste utilisable même sans données
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _choisirPeriode(String periode) {
    if (periode == "Aujourd'hui") {
      setState(() => _periode = periode);
      return;
    }
    setState(() => _periode = periode);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Prévisions "$periode" bientôt disponibles — seules celles du jour sont calculées pour le moment.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final heures = _previsions?.heuresDePointe ?? [];

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Prédictions du trafic', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const Text('Prévisions pour les prochaines heures', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: ["Aujourd'hui", 'Dans 1h', 'Ce soir', 'Demain']
                .map((p) => ChoiceChip(
                      label: Text(p, style: const TextStyle(fontSize: 12)),
                      selected: _periode == p,
                      onSelected: (_) => _choisirPeriode(p),
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(color: _periode == p ? Colors.white : AppColors.textPrimary),
                    ))
                .toList(),
          ),
          const SizedBox(height: 14),
          const _BaseMap(markers: []),
          const SizedBox(height: 10),
          const _LegendRow(),
          const SizedBox(height: 18),
          const Text('Heures de pointe prévues', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 10),
          if (heures.isEmpty)
            const Text('Données indisponibles.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13))
          else
            Row(
              children: [
                for (var i = 0; i < heures.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(child: _HeureButton(heure: heures[i], selected: i == _creneauSelectionne, onTap: () => setState(() => _creneauSelectionne = i))),
                ],
              ],
            ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Zones à risque', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    if (_previsions == null || _previsions!.zonesARisque.isEmpty)
                      const Text('Aucune.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12))
                    else
                      ..._previsions!.zonesARisque.map((z) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(z.zone, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                Text(z.creneau, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                Text(z.niveau, style: TextStyle(fontSize: 11, color: AppColors.trafficColor(z.niveau), fontWeight: FontWeight.w600)),
                              ],
                            ),
                          )),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Itinéraires recommandés', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    if (_recommandes.isEmpty)
                      const Text('Ajoute Domicile et Travail dans tes favoris.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12))
                    else
                      ..._recommandes.map((r) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${r.origineLabel} → ${r.destinationLabel}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                Text(
                                  [if (r.dureeMin != null) '${r.dureeMin!.round()} min', 'Trafic ${r.trafic}'].join(' · '),
                                  style: TextStyle(fontSize: 11, color: AppColors.trafficColor(r.trafic)),
                                ),
                              ],
                            ),
                          )),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
            child: Text(
              'Ces prédictions sont basées sur l\'historique du trafic et les conditions actuelles.'
              '${_previsions != null ? " Dernière mise à jour : aujourd'hui à ${TimeOfDay.now().format(context)}." : ''}',
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeureButton extends StatelessWidget {
  final PeakHour heure;
  final bool selected;
  final VoidCallback onTap;
  const _HeureButton({required this.heure, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.trafficColor(heure.niveau);
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? color : color.withValues(alpha: 0.3), width: selected ? 1.5 : 1),
        ),
        child: Column(
          children: [
            Text(heure.heure, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
            Text(heure.niveau, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

/// Onglet 'Incidents' — signalements récents (reports/).
class _IncidentsTab extends StatefulWidget {
  const _IncidentsTab();

  @override
  State<_IncidentsTab> createState() => _IncidentsTabState();
}

class _IncidentsTabState extends State<_IncidentsTab> {
  final _service = ReportsService();
  List<Report> _reports = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _service.list(pageSize: 20).then((r) {
      if (mounted) setState(() {
        _reports = r;
        _loading = false;
      });
    }).catchError((_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_reports.isEmpty) return const Center(child: Text('Aucun incident récent.', style: TextStyle(color: AppColors.textSecondary)));

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _reports.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final r = _reports[i];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
          child: Row(
            children: [
              ReportTypeIcon(type: r.type, size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.typeLabel, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    Text(r.zone, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              Text(r.ilYA, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
            ],
          ),
        );
      },
    );
  }
}

/// Onglet 'Zones inondables' — segments à risque sous alerte météo active
/// (environment/WeatherAlertsView, même source que le dashboard web).
class _ZonesInondablesTab extends StatefulWidget {
  const _ZonesInondablesTab();

  @override
  State<_ZonesInondablesTab> createState() => _ZonesInondablesTabState();
}

class _ZonesInondablesTabState extends State<_ZonesInondablesTab> {
  final _service = WeatherService();
  List<RoadSegment> _segments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _service.alerts().then((s) {
      if (mounted) setState(() {
        _segments = s;
        _loading = false;
      });
    }).catchError((_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_segments.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Aucune zone inondable sous alerte pour le moment.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _BaseMap(
          height: 220,
          markers: _segments
              .map((s) => Marker(
                    point: LatLng(s.latitude, s.longitude),
                    width: 26,
                    height: 26,
                    child: const Icon(Icons.water_drop_rounded, color: AppColors.inondation, size: 26),
                  ))
              .toList(),
        ),
        const SizedBox(height: 14),
        ..._segments.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.inondation.withValues(alpha: 0.3))),
                child: Row(
                  children: [
                    const Icon(Icons.water_drop_rounded, color: AppColors.inondation, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.nom, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          Text(s.zone, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }
}
