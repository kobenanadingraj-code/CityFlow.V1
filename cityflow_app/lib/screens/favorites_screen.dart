import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/profile_service.dart';
import '../theme/app_theme.dart';

/// Écran 7 — Favoris (lieux enregistrés : Domicile, Travail, autres favoris).
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final _service = ProfileService();
  List<SavedPlace> _lieux = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final lieux = await _service.getLieux();
      if (!mounted) return;
      setState(() => _lieux = lieux);
    } catch (_) {
      // liste vide en cas d'échec réseau
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'maison':
        return Icons.home_rounded;
      case 'travail':
        return Icons.work_rounded;
      default:
        return Icons.star_rounded;
    }
  }

  Future<void> _openAddSheet() async {
    final typeCtrl = ValueNotifier<String>('favori');
    final labelCtrl = TextEditingController();
    final adresseCtrl = TextEditingController();
    final latCtrl = TextEditingController();
    final lngCtrl = TextEditingController();

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Ajouter un lieu', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ValueListenableBuilder<String>(
                valueListenable: typeCtrl,
                builder: (context, value, _) => Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Maison'),
                      selected: value == 'maison',
                      onSelected: (_) => typeCtrl.value = 'maison',
                    ),
                    ChoiceChip(
                      label: const Text('Travail'),
                      selected: value == 'travail',
                      onSelected: (_) => typeCtrl.value = 'travail',
                    ),
                    ChoiceChip(
                      label: const Text('Favori'),
                      selected: value == 'favori',
                      onSelected: (_) => typeCtrl.value = 'favori',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              TextField(controller: labelCtrl, decoration: const InputDecoration(hintText: 'Nom du lieu (ex : Bureau)')),
              const SizedBox(height: 10),
              TextField(controller: adresseCtrl, decoration: const InputDecoration(hintText: 'Adresse')),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: latCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      decoration: const InputDecoration(hintText: 'Latitude'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: lngCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      decoration: const InputDecoration(hintText: 'Longitude'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: () async {
                  final lat = double.tryParse(latCtrl.text.trim());
                  final lng = double.tryParse(lngCtrl.text.trim());
                  if (lat == null || lng == null) return;
                  await _service.addLieu(SavedPlace(
                    id: 0,
                    type: typeCtrl.value,
                    label: labelCtrl.text.trim(),
                    adresse: adresseCtrl.text.trim(),
                    latitude: lat,
                    longitude: lng,
                  ));
                  if (context.mounted) Navigator.of(context).pop(true);
                },
                child: const Text('Enregistrer'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
    if (saved == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favoris'),
        actions: [IconButton(icon: const Icon(Icons.add), onPressed: _openAddSheet)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _lieux.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_outline_rounded, size: 48, color: AppColors.textMuted),
                      const SizedBox(height: 12),
                      const Text('Aucun lieu enregistré.', style: TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 12),
                      OutlinedButton(onPressed: _openAddSheet, child: const Text('Ajouter un lieu')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _lieux.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final lieu = _lieux[i];
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                              child: Icon(_iconFor(lieu.type), color: AppColors.primary, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(lieu.displayLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  if (lieu.adresse.isNotEmpty)
                                    Text(lieu.adresse, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.textMuted, size: 20),
                              onPressed: () async {
                                await _service.deleteLieu(lieu.id);
                                _load();
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
