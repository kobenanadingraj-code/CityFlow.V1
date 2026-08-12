import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/report.dart';
import '../services/api_client.dart';
import '../services/reports_service.dart';
import '../theme/app_theme.dart';
import '../widgets/report_type_icon.dart';

/// Écran 'Envoyer un signalement' — bouton + sur Alertes.
class ReportCreateScreen extends StatefulWidget {
  const ReportCreateScreen({super.key});

  @override
  State<ReportCreateScreen> createState() => _ReportCreateScreenState();
}

class _ReportCreateScreenState extends State<ReportCreateScreen> {
  final _service = ReportsService();
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  final _zoneCtrl = TextEditingController();
  final _adresseCtrl = TextEditingController();
  String _type = 'accident';
  bool _loading = false;
  String? _error;
  Uint8List? _photoBytes;
  String? _photoFileName;

  static const _types = ['accident', 'embouteillage', 'inondation', 'travaux', 'autre'];

  @override
  void dispose() {
    _descCtrl.dispose();
    _zoneCtrl.dispose();
    _adresseCtrl.dispose();
    super.dispose();
  }

  Future<void> _choisirPhoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _photoBytes = bytes;
      _photoFileName = picked.name;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _service.create(
        ReportCreatePayload(
          type: _type,
          description: _descCtrl.text.trim(),
          zone: _zoneCtrl.text.trim(),
          adresse: _adresseCtrl.text.trim(),
        ),
        photoBytes: _photoBytes,
        photoFileName: _photoFileName,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Une erreur est survenue. Réessaie.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Envoyer un signalement')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.accident.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(_error!, style: const TextStyle(color: AppColors.accident, fontSize: 13)),
                  ),
                  const SizedBox(height: 16),
                ],
                const Text('Type d\'incident', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _types.map((t) {
                    final selected = t == _type;
                    return ChoiceChip(
                      selected: selected,
                      onSelected: (_) => setState(() => _type = t),
                      avatar: ReportTypeIcon(type: t, size: 22),
                      label: Text(Report.typeLabels[t] ?? t),
                      selectedColor: AppColors.primary.withValues(alpha: 0.12),
                      labelStyle: TextStyle(
                        color: selected ? AppColors.primary : AppColors.textPrimary,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                      ),
                      side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                const Text('Commune / zone', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _zoneCtrl,
                  decoration: const InputDecoration(hintText: 'Ex : Cocody'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                ),
                const SizedBox(height: 16),
                const Text('Adresse précise', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _adresseCtrl,
                  decoration: const InputDecoration(hintText: 'Ex : Carrefour Angré 8e Tranche'),
                ),
                const SizedBox(height: 16),
                const Text('Photo (optionnelle)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 8),
                if (_photoBytes != null)
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(_photoBytes!, height: 160, width: double.infinity, fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.black54,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.close_rounded, size: 16, color: Colors.white),
                            onPressed: () => setState(() {
                              _photoBytes = null;
                              _photoFileName = null;
                            }),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  OutlinedButton.icon(
                    onPressed: _choisirPhoto,
                    icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                    label: const Text('Ajouter une photo'),
                  ),
                const SizedBox(height: 16),
                const Text('Description', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(hintText: 'Décris la situation...'),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : const Text('Envoyer le signalement'),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
