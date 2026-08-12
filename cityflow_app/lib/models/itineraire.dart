/// Résultat d'un itinéraire calculé (écran Trajet, recherche libre).
class ItineraireResult {
  final String type; // recommande | autre | alternatif
  final String destinationLabel;
  final double? distanceKm;
  final double? dureeMin;
  final String trafic; // fluide | modéré | dense | inconnu
  final int? scoreCongestion;
  /// Points [lng, lat] du tracé OSRM (overview=simplified) — pour dessiner
  /// l'itinéraire sur la carte de l'écran Trajet.
  final List<List<double>> geometry;

  ItineraireResult({
    required this.type,
    required this.destinationLabel,
    this.distanceKm,
    this.dureeMin,
    required this.trafic,
    this.scoreCongestion,
    this.geometry = const [],
  });

  factory ItineraireResult.fromJson(Map<String, dynamic> json) => ItineraireResult(
        type: json['type'] as String,
        destinationLabel: json['destination_label'] as String? ?? '',
        distanceKm: (json['distance_km'] as num?)?.toDouble(),
        dureeMin: (json['duree_min'] as num?)?.toDouble(),
        trafic: json['trafic'] as String? ?? 'inconnu',
        scoreCongestion: json['score_congestion'] as int?,
        geometry: (json['geometry'] as List?)
                ?.map((p) => (p as List).map((v) => (v as num).toDouble()).toList())
                .toList() ??
            const [],
      );

  static const typeLabels = {
    'recommande': 'Itinéraire recommandé',
    'autre': 'Autre itinéraire',
    'alternatif': 'Itinéraire alternatif',
  };

  String get typeLabel => typeLabels[type] ?? type;
}

/// Itinéraire favori précalculé (écran Carte, bloc 'Itinéraires recommandés').
class ItineraireRecommande {
  final String origineLabel;
  final String destinationLabel;
  final double? distanceKm;
  final double? dureeMin;
  final String trafic;

  ItineraireRecommande({
    required this.origineLabel,
    required this.destinationLabel,
    this.distanceKm,
    this.dureeMin,
    required this.trafic,
  });

  factory ItineraireRecommande.fromJson(Map<String, dynamic> json) => ItineraireRecommande(
        origineLabel: json['origine_label'] as String,
        destinationLabel: json['destination_label'] as String,
        distanceKm: (json['distance_km'] as num?)?.toDouble(),
        dureeMin: (json['duree_min'] as num?)?.toDouble(),
        trafic: json['trafic'] as String? ?? 'inconnu',
      );
}
