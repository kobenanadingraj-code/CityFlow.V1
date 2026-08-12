import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/mobility.dart';
import '../models/report.dart';
import '../models/weather.dart';
import '../services/auth_service.dart';
import '../services/mobility_service.dart';
import '../services/notifications_service.dart';
import '../services/reports_service.dart';
import '../services/weather_service.dart';
import '../theme/app_theme.dart';
import '../utils/traffic_level.dart';
import '../widgets/report_type_icon.dart';
import 'notifications_screen.dart';
import 'trajet_screen.dart';

/// Écran 4 — Accueil.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _weatherService = WeatherService();
  final _mobilityService = MobilityService();
  final _reportsService = ReportsService();
  final _notificationsService = NotificationsService();

  WeatherEvent? _weather;
  List<CommuneStats> _communes = [];
  List<Report> _reports = [];
  int _unread = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final user = context.read<AuthService>().currentUser;
    try {
      final results = await Future.wait([
        _weatherService.current(zone: user?.zone),
        _mobilityService.communes(),
        _reportsService.list(pageSize: 4),
        _notificationsService.unreadCount(),
      ]);
      if (!mounted) return;
      setState(() {
        _weather = results[0] as WeatherEvent?;
        _communes = results[1] as List<CommuneStats>;
        _reports = results[2] as List<Report>;
        _unread = results[3] as int;
      });
    } catch (_) {
      // Écran reste utilisable même si un appel échoue (ex: OSRM/API down)
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String get _trafficLabel {
    if (_communes.isEmpty) return '—';
    final avg = _communes.map((c) => c.scoreMoyen).reduce((a, b) => a + b) / _communes.length;
    return trafficLabelFromScore(avg);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    final prenom = (user?.nomComplet ?? '').split(' ').firstOrNull ?? '';

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Bonjour,', style: TextStyle(color: AppColors.textSecondary)),
                      Text(
                        prenom.isEmpty ? (user?.nomComplet ?? '') : '$prenom 👋',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_none_rounded, size: 26),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                        ),
                      ),
                      if (_unread > 0)
                        Positioned(
                          right: 6,
                          top: 6,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(color: AppColors.accident, shape: BoxShape.circle),
                            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                            child: Text(
                              '$_unread',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _InfoCard(
                      label: 'Trafic actuel',
                      value: _trafficLabel,
                      valueColor: AppColors.trafficColor(_trafficLabel.toLowerCase()),
                      icon: Icons.speed_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _InfoCard(
                      label: 'Météo',
                      value: _weather != null
                          ? '${_weather!.temperatureRounded}°C, ${_weather!.conditionLabel}'
                          : '—',
                      valueColor: AppColors.textPrimary,
                      icon: Icons.wb_sunny_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TrajetScreen()),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.search_rounded, color: AppColors.textMuted),
                      SizedBox(width: 10),
                      Text('Où allez-vous ?', style: TextStyle(color: AppColors.textMuted)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Infos en temps réel', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_reports.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('Rien à signaler pour le moment.', style: TextStyle(color: AppColors.textSecondary))),
                )
              else
                ..._reports.map((r) => _ReportTile(report: r)),
            ],
          ),
        ),
      ),
    );
  }
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

class _InfoCard extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final IconData icon;

  const _InfoCard({required this.label, required this.value, required this.valueColor, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 16, color: AppColors.textMuted),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ]),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: valueColor)),
        ],
      ),
    );
  }
}

class _ReportTile extends StatelessWidget {
  final Report report;
  const _ReportTile({required this.report});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            ReportTypeIcon(type: report.type, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(report.typeLabel, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  Text(report.zone, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.typeColor(report.type)),
          ],
        ),
      ),
    );
  }
}
