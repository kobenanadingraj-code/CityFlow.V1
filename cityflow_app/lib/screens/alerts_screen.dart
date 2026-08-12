import 'package:flutter/material.dart';

import '../models/report.dart';
import '../services/reports_service.dart';
import '../theme/app_theme.dart';
import '../widgets/report_type_icon.dart';
import 'report_create_screen.dart';

/// Écran 6 — Alertes (liste des signalements en cours).
class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final _service = ReportsService();
  List<Report> _reports = [];
  bool _loading = true;
  String _typeFiltre = 'toutes';

  static const _filtres = {
    'toutes': 'Toutes',
    'accident': 'Accidents',
    'inondation': 'Inondations',
    'travaux': 'Travaux',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final reports = await _service.list(type: _typeFiltre, pageSize: 30);
      if (!mounted) return;
      setState(() => _reports = reports);
    } catch (_) {
      // liste vide en cas d'échec réseau
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signaler() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const ReportCreateScreen()),
    );
    if (created == true) _load();
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Alertes', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        SizedBox(height: 2),
                        Text('Informations importantes en temps réel', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _filtres.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final key = _filtres.keys.elementAt(i);
                  final selected = key == _typeFiltre;
                  return ChoiceChip(
                    label: Text(_filtres[key]!),
                    selected: selected,
                    onSelected: (_) {
                      setState(() => _typeFiltre = key);
                      _load();
                    },
                    selectedColor: AppColors.textPrimary,
                    backgroundColor: AppColors.background,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : AppColors.textPrimary,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 13,
                    ),
                    side: BorderSide(color: selected ? AppColors.textPrimary : AppColors.border),
                  );
                },
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _reports.isEmpty
                      ? const Center(
                          child: Text('Aucune alerte pour ce filtre.', style: TextStyle(color: AppColors.textSecondary)),
                        )
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                            itemCount: _reports.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, i) => _AlertCard(report: _reports[i]),
                          ),
                        ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: ElevatedButton.icon(
                onPressed: _signaler,
                icon: const Icon(Icons.send_rounded, size: 18),
                label: const Text('Envoyer un signalement'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final Report report;
  const _AlertCard({required this.report});

  IconData get _icon {
    switch (report.type) {
      case 'inondation':
        return Icons.water_drop_rounded;
      default:
        return Icons.warning_amber_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = AppColors.typeColor(report.type);
    final titre = report.description.isNotEmpty ? report.description : report.typeLabel;
    final soustitre = report.adresse.isNotEmpty ? report.adresse : report.zone;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          ReportTypeIcon(type: report.type, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titre, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 2),
                Text(soustitre, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Icon(_icon, size: 16, color: color),
              const SizedBox(height: 4),
              Text(report.ilYA, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}
