import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/export_job.dart';
import '../../services/exports_service.dart';
import '../../theme/app_theme.dart';

/// Écran 11 — Export des données (dashboard web, autorités).
class ExportsScreen extends StatefulWidget {
  const ExportsScreen({super.key});

  @override
  State<ExportsScreen> createState() => _ExportsScreenState();
}

class _ExportsScreenState extends State<ExportsScreen> {
  final _service = ExportsService();
  final _nomCtrl = TextEditingController();
  final _dateFmt = DateFormat('dd/MM/yyyy');

  String _typeDonnees = 'signalements';
  String _format = 'csv';
  DateTime _debut = DateTime.now().subtract(const Duration(days: 30));
  DateTime _fin = DateTime.now();

  List<ExportJob> _jobs = [];
  bool _loading = true;
  bool _creating = false;

  static const _types = {
    'signalements': 'Signalements',
    'utilisateurs': 'Utilisateurs',
    'alertes': 'Alertes météo',
    'statistiques': 'Statistiques',
  };
  static const _formats = {'csv': 'CSV', 'xlsx': 'Excel (XLSX)', 'pdf': 'PDF'};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final jobs = await _service.list();
      if (!mounted) return;
      setState(() => _jobs = jobs);
    } catch (_) {
      // liste vide en cas d'échec réseau
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDate({required bool debut}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: debut ? _debut : _fin,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    setState(() => debut ? _debut = picked : _fin = picked);
  }

  Future<void> _generer() async {
    setState(() => _creating = true);
    try {
      await _service.create(
        typeDonnees: _typeDonnees,
        periodeDebut: _debut,
        periodeFin: _fin,
        format: _format,
        nom: _nomCtrl.text.trim(),
      );
      _nomCtrl.clear();
      await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Échec de la génération de l\'export.')),
        );
      }
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Export des données', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Génère un export CSV, Excel ou PDF des données CityFlow AI.', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Wrap(
              spacing: 14,
              runSpacing: 14,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [
                SizedBox(
                  width: 200,
                  child: TextField(controller: _nomCtrl, decoration: const InputDecoration(labelText: 'Nom (optionnel)')),
                ),
                SizedBox(
                  width: 190,
                  child: DropdownButtonFormField<String>(
                    value: _typeDonnees,
                    decoration: const InputDecoration(labelText: 'Données'),
                    items: _types.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                    onChanged: (v) => setState(() => _typeDonnees = v ?? _typeDonnees),
                  ),
                ),
                SizedBox(
                  width: 160,
                  child: DropdownButtonFormField<String>(
                    value: _format,
                    decoration: const InputDecoration(labelText: 'Format'),
                    items: _formats.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                    onChanged: (v) => setState(() => _format = v ?? _format),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _pickDate(debut: true),
                  icon: const Icon(Icons.calendar_today_rounded, size: 15),
                  label: Text('Du ${_dateFmt.format(_debut)}'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _pickDate(debut: false),
                  icon: const Icon(Icons.calendar_today_rounded, size: 15),
                  label: Text('Au ${_dateFmt.format(_fin)}'),
                ),
                ElevatedButton.icon(
                  onPressed: _creating ? null : _generer,
                  icon: _creating
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.file_download_rounded, size: 18),
                  label: const Text('Générer l\'export'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Exports récents', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          if (_loading)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
          else if (_jobs.isEmpty)
            const Text('Aucun export généré pour le moment.', style: TextStyle(color: AppColors.textSecondary))
          else
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: _jobs.map((j) => _ExportRow(job: j, dateFmt: _dateFmt)).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _ExportRow extends StatelessWidget {
  final ExportJob job;
  final DateFormat dateFmt;
  const _ExportRow({required this.job, required this.dateFmt});

  Color get _statutColor {
    switch (job.statut) {
      case 'termine':
        return AppColors.success;
      case 'echec':
        return AppColors.accident;
      default:
        return AppColors.embouteillage;
    }
  }

  String get _statutLabel {
    switch (job.statut) {
      case 'termine':
        return 'Terminé';
      case 'echec':
        return 'Échec';
      default:
        return 'En cours';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.description_outlined, color: AppColors.textMuted, size: 20),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(job.nom.isEmpty ? job.typeDonnees : job.nom, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Text(
                  '${dateFmt.format(job.periodeDebut)} → ${dateFmt.format(job.periodeFin)} · ${job.format.toUpperCase()} · ${job.tailleLisible}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: _statutColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
            child: Text(_statutLabel, style: TextStyle(color: _statutColor, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 10),
          if (job.fichierUrl != null)
            IconButton(
              icon: const Icon(Icons.download_rounded, color: AppColors.primary, size: 20),
              tooltip: 'Télécharger',
              onPressed: () => launchUrl(Uri.parse(job.fichierUrl!), mode: LaunchMode.externalApplication),
            ),
        ],
      ),
    );
  }
}
