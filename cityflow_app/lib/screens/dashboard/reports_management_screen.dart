import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/report.dart';
import '../../services/reports_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/report_type_icon.dart';

/// Écran 10 — Gestion des signalements (dashboard web, autorités).
class ReportsManagementScreen extends StatefulWidget {
  const ReportsManagementScreen({super.key});

  @override
  State<ReportsManagementScreen> createState() => _ReportsManagementScreenState();
}

class _ReportsManagementScreenState extends State<ReportsManagementScreen> {
  final _service = ReportsService();
  final _searchCtrl = TextEditingController();
  List<Report> _reports = [];
  bool _loading = true;
  String _type = 'toutes';
  String? _statut;
  final _dateFmt = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final reports = await _service.list(
        type: _type,
        statut: _statut,
        q: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
        pageSize: 50,
      );
      if (!mounted) return;
      setState(() => _reports = reports);
    } catch (_) {
      // liste vide en cas d'échec réseau
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _changerStatut(Report r, String statut) async {
    await _service.updateStatutPriorite(r.id, statut: statut);
    _load();
  }

  Future<void> _supprimer(Report r) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le signalement'),
        content: Text('Supprimer définitivement « ${r.typeLabel} — ${r.zone} » ?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Supprimer')),
        ],
      ),
    );
    if (confirm == true) {
      await _service.delete(r.id);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Gestion des signalements', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Filtrer, mettre à jour le statut et modérer les signalements citoyens.', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 240,
                child: TextField(
                  controller: _searchCtrl,
                  decoration: const InputDecoration(hintText: 'Rechercher (zone, adresse...)', prefixIcon: Icon(Icons.search_rounded)),
                  onSubmitted: (_) => _load(),
                ),
              ),
              DropdownButton<String>(
                value: _type,
                items: const [
                  DropdownMenuItem(value: 'toutes', child: Text('Tous les types')),
                  DropdownMenuItem(value: 'accident', child: Text('Accident')),
                  DropdownMenuItem(value: 'embouteillage', child: Text('Embouteillage')),
                  DropdownMenuItem(value: 'inondation', child: Text('Inondation')),
                  DropdownMenuItem(value: 'travaux', child: Text('Travaux')),
                  DropdownMenuItem(value: 'autre', child: Text('Autre')),
                ],
                onChanged: (v) {
                  setState(() => _type = v ?? 'toutes');
                  _load();
                },
              ),
              DropdownButton<String?>(
                value: _statut,
                hint: const Text('Tous les statuts'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Tous les statuts')),
                  DropdownMenuItem(value: 'nouveau', child: Text('Nouveau')),
                  DropdownMenuItem(value: 'en_cours', child: Text('En cours')),
                  DropdownMenuItem(value: 'resolu', child: Text('Résolu')),
                  DropdownMenuItem(value: 'en_attente', child: Text('En attente')),
                ],
                onChanged: (v) {
                  setState(() => _statut = v);
                  _load();
                },
              ),
              OutlinedButton.icon(onPressed: _load, icon: const Icon(Icons.refresh_rounded, size: 16), label: const Text('Actualiser')),
            ],
          ),
          const SizedBox(height: 18),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _reports.isEmpty
                    ? const Center(child: Text('Aucun signalement pour ces filtres.', style: TextStyle(color: AppColors.textSecondary)))
                    : Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: SingleChildScrollView(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(AppColors.background),
                              columns: const [
                                DataColumn(label: Text('Type')),
                                DataColumn(label: Text('Zone / adresse')),
                                DataColumn(label: Text('Priorité')),
                                DataColumn(label: Text('Statut')),
                                DataColumn(label: Text('Confirmations')),
                                DataColumn(label: Text('Date')),
                                DataColumn(label: Text('Actions')),
                              ],
                              rows: _reports.map((r) {
                                return DataRow(cells: [
                                  DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                                    ReportTypeIcon(type: r.type, size: 26),
                                    const SizedBox(width: 8),
                                    Text(r.typeLabel),
                                  ])),
                                  DataCell(SizedBox(
                                    width: 200,
                                    child: Text('${r.zone}${r.adresse.isNotEmpty ? ' · ${r.adresse}' : ''}',
                                        overflow: TextOverflow.ellipsis),
                                  )),
                                  DataCell(_Badge(text: r.prioriteLabel, color: _prioriteColor(r.priorite))),
                                  DataCell(DropdownButton<String>(
                                    value: r.statut,
                                    underline: const SizedBox(),
                                    items: Report.statutLabels.entries
                                        .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, style: const TextStyle(fontSize: 13))))
                                        .toList(),
                                    onChanged: (v) {
                                      if (v != null) _changerStatut(r, v);
                                    },
                                  )),
                                  DataCell(Text('${r.nbConfirmations}')),
                                  DataCell(Text(_dateFmt.format(r.createdAt), style: const TextStyle(fontSize: 12))),
                                  DataCell(IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.accident, size: 19),
                                    onPressed: () => _supprimer(r),
                                  )),
                                ]);
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Color _prioriteColor(String priorite) {
    switch (priorite) {
      case 'elevee':
        return AppColors.accident;
      case 'moyenne':
        return AppColors.embouteillage;
      default:
        return AppColors.textMuted;
    }
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
