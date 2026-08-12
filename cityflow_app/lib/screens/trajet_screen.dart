import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/itineraire.dart';
import '../models/user.dart';
import '../services/api_client.dart';
import '../services/conseil_service.dart';
import '../services/profile_service.dart';
import '../theme/app_theme.dart';

/// Position par défaut utilisée comme origine tant que l'utilisateur n'a
/// pas de lieu 'Maison' enregistré et que la géolocalisation GPS n'est pas
/// câblée (le package geolocator n'est pas encore ajouté au projet — voir
/// INTEGRATION.md). Plateau, centre d'Abidjan.
final _positionParDefaut = SavedPlace(id: -1, type: 'autre', label: 'Ma position', adresse: 'Plateau, Abidjan', latitude: 5.3097, longitude: -4.0125);

/// Écran Trajet — recherche libre avec tracé sur carte, à l'image de la maquette.
class TrajetScreen extends StatefulWidget {
  const TrajetScreen({super.key});

  @override
  State<TrajetScreen> createState() => _TrajetScreenState();
}

class _TrajetScreenState extends State<TrajetScreen> {
  final _conseilService = ConseilService();
  final _profileService = ProfileService();

  List<SavedPlace> _lieux = [];
  SavedPlace? _origine;
  SavedPlace? _destination;
  String _mode = 'voiture';
  List<ItineraireResult> _resultats = [];
  String? _conseil;
  int _selection = 0;
  bool _loadingInit = true;
  bool _loadingRecherche = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loadingInit = true);
    try {
      final lieux = await _profileService.getLieux();
      if (!mounted) return;
      final maison = lieux.where((l) => l.type == 'maison').toList();
      final travail = lieux.where((l) => l.type == 'travail').toList();
      setState(() {
        _lieux = lieux;
        _origine = maison.isNotEmpty ? maison.first : _positionParDefaut;
        _destination = travail.isNotEmpty ? travail.first : null;
      });
      if (_destination != null) _rechercher();
    } catch (_) {
      // écran reste utilisable sans lieux enregistrés
    } finally {
      if (mounted) setState(() => _loadingInit = false);
    }
  }

  void _swap() {
    setState(() {
      final tmp = _origine;
      _origine = _destination ?? _positionParDefaut;
      _destination = tmp;
    });
    if (_destination != null) _rechercher();
  }

  Future<void> _choisirLieu({required bool pourOrigine}) async {
    final options = [_positionParDefaut, ..._lieux];
    final choix = await showModalBottomSheet<SavedPlace>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(pourOrigine ? 'Choisir le départ' : 'Choisir la destination', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
            ...options.map((l) => ListTile(
                  leading: Icon(l.type == 'maison' ? Icons.home_rounded : l.type == 'travail' ? Icons.work_rounded : Icons.place_rounded, color: AppColors.primary),
                  title: Text(l.displayLabel),
                  subtitle: l.adresse.isNotEmpty ? Text(l.adresse) : null,
                  onTap: () => Navigator.of(context).pop(l),
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (choix == null) return;
    setState(() {
      if (pourOrigine) {
        _origine = choix;
      } else {
        _destination = choix;
      }
    });
    if (_origine != null && _destination != null) _rechercher();
  }

  Future<void> _rechercher() async {
    final origine = _origine;
    final destination = _destination;
    if (origine == null || destination == null) return;
    setState(() {
      _loadingRecherche = true;
      _error = null;
      _resultats = [];
      _conseil = null;
      _selection = 0;
    });
    try {
      final data = await _conseilService.trajetLibre(
        origineLat: origine.latitude,
        origineLng: origine.longitude,
        destinationLat: destination.latitude,
        destinationLng: destination.longitude,
        destinationLabel: destination.displayLabel,
      );
      if (!mounted) return;
      setState(() {
        _resultats = data['itineraires'] as List<ItineraireResult>;
        _conseil = data['conseil'] as String?;
      });
    } on ApiException catch (e) {
      setState(() => _error = e.statusCode == 503 ? "Le calcul d'itinéraire n'est pas disponible pour le moment." : e.message);
    } catch (_) {
      setState(() => _error = 'Une erreur est survenue. Réessaie.');
    } finally {
      if (mounted) setState(() => _loadingRecherche = false);
    }
  }

  Future<void> _demarrer() async {
    final destination = _destination;
    if (destination == null) return;
    final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${destination.latitude},${destination.longitude}&travelmode=driving');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final itineraire = _resultats.isNotEmpty ? _resultats[_selection.clamp(0, _resultats.length - 1)] : null;
    final points = itineraire == null ? <LatLng>[] : itineraire.geometry.map((p) => LatLng(p[1], p[0])).toList();
    final centre = points.isNotEmpty ? points[points.length ~/ 2] : const LatLng(5.3097, -4.0125);

    return Scaffold(
      appBar: AppBar(title: const Text('Trajet')),
      body: _loadingInit
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              _LieuField(icon: Icons.circle, iconColor: AppColors.success, label: _origine?.displayLabel ?? 'Choisir le départ', onTap: () => _choisirLieu(pourOrigine: true)),
                              const Divider(height: 1),
                              _LieuField(icon: Icons.location_on, iconColor: AppColors.accident, label: _destination?.displayLabel ?? 'Choisir la destination', onTap: () => _choisirLieu(pourOrigine: false)),
                            ],
                          ),
                        ),
                        IconButton(icon: const Icon(Icons.swap_vert_rounded), onPressed: _swap),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _ModeButton(icon: Icons.directions_car_rounded, selected: _mode == 'voiture', onTap: () => setState(() => _mode = 'voiture')),
                      const SizedBox(width: 10),
                      _ModeButton(icon: Icons.directions_bus_rounded, selected: _mode == 'bus', onTap: () => setState(() => _mode = 'bus'), enabled: false),
                      const SizedBox(width: 10),
                      _ModeButton(icon: Icons.directions_bike_rounded, selected: _mode == 'velo', onTap: () => setState(() => _mode = 'velo'), enabled: false),
                      const SizedBox(width: 10),
                      _ModeButton(icon: Icons.directions_walk_rounded, selected: _mode == 'pied', onTap: () => setState(() => _mode = 'pied'), enabled: false),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      height: 200,
                      child: FlutterMap(
                        options: MapOptions(initialCenter: centre, initialZoom: points.isEmpty ? 12 : 13),
                        children: [
                          TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.cityflow.app'),
                          if (points.isNotEmpty)
                            PolylineLayer(polylines: [
                              Polyline(points: points, strokeWidth: 5, color: AppColors.trafficColor(itineraire!.trafic)),
                            ]),
                          if (points.isNotEmpty)
                            MarkerLayer(markers: [
                              Marker(point: points.first, width: 16, height: 16, child: const _Dot(color: AppColors.success)),
                              Marker(point: points.last, width: 16, height: 16, child: const _Dot(color: AppColors.accident)),
                            ]),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (_loadingRecherche) const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())),
                  if (_error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(color: AppColors.accident.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                      child: Text(_error!, style: const TextStyle(color: AppColors.accident, fontSize: 13)),
                    ),
                  for (var i = 0; i < _resultats.length; i++)
                    _ItineraireCard(itineraire: _resultats[i], selected: i == _selection, onTap: () => setState(() => _selection = i)),
                  if (_conseil != null)
                    Container(
                      margin: const EdgeInsets.only(top: 4, bottom: 14),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time_rounded, color: AppColors.primary, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_conseil!, style: const TextStyle(fontSize: 13))),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: itineraire == null ? null : _demarrer,
                    icon: const Icon(Icons.navigation_rounded, size: 18),
                    label: const Text('Démarrer'),
                  ),
                ],
              ),
            ),
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot({required this.color});
  @override
  Widget build(BuildContext context) => Container(decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)));
}

class _LieuField extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;
  const _LieuField({required this.icon, required this.iconColor, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 12, color: iconColor),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
          ],
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final bool enabled;
  const _ModeButton({required this.icon, required this.selected, required this.onTap, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? AppColors.primary : AppColors.border),
          ),
          child: Icon(icon, color: selected ? Colors.white : (enabled ? AppColors.textPrimary : AppColors.textMuted), size: 20),
        ),
      ),
    );
  }
}

class _ItineraireCard extends StatelessWidget {
  final ItineraireResult itineraire;
  final bool selected;
  final VoidCallback onTap;
  const _ItineraireCard({required this.itineraire, required this.selected, required this.onTap});

  IconData get _icon {
    switch (itineraire.type) {
      case 'recommande':
        return Icons.check_circle_rounded;
      case 'autre':
        return Icons.warning_rounded;
      default:
        return Icons.trending_up_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = AppColors.trafficColor(itineraire.trafic);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: selected ? 1.5 : 1),
          ),
          child: Row(
            children: [
              Icon(_icon, color: color, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      [
                        if (itineraire.dureeMin != null) '${itineraire.dureeMin!.round()} min',
                        if (itineraire.distanceKm != null) '${itineraire.distanceKm!.toStringAsFixed(1)} km',
                      ].join(' · '),
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: color),
                    ),
                    Text('Trafic ${itineraire.trafic}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
