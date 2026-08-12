class Report {
  final int id;
  final String type; // accident | embouteillage | inondation | travaux | autre
  final String description;
  final String? photo;
  final String zone;
  final String adresse;
  final double? latitude;
  final double? longitude;
  final int? segment;
  final String? segmentNom;
  final String priorite; // elevee | moyenne | faible
  final String statut; // nouveau | en_cours | resolu | en_attente
  final int nbConfirmations;
  final String signalePar;
  final DateTime createdAt;
  final DateTime updatedAt;

  Report({
    required this.id,
    required this.type,
    required this.description,
    this.photo,
    required this.zone,
    required this.adresse,
    this.latitude,
    this.longitude,
    this.segment,
    this.segmentNom,
    required this.priorite,
    required this.statut,
    required this.nbConfirmations,
    required this.signalePar,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Report.fromJson(Map<String, dynamic> json) => Report(
        id: json['id'] as int,
        type: json['type'] as String,
        description: json['description'] as String? ?? '',
        photo: json['photo'] as String?,
        zone: json['zone'] as String? ?? '',
        adresse: json['adresse'] as String? ?? '',
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        segment: json['segment'] as int?,
        segmentNom: json['segment_nom'] as String?,
        priorite: json['priorite'] as String? ?? 'moyenne',
        statut: json['statut'] as String? ?? 'nouveau',
        nbConfirmations: json['nb_confirmations'] as int? ?? 1,
        signalePar: json['signale_par'] as String? ?? '',
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  static const typeLabels = {
    'accident': 'Accident',
    'embouteillage': 'Embouteillage',
    'inondation': 'Route inondée',
    'travaux': 'Travaux en cours',
    'autre': 'Autre',
  };

  static const statutLabels = {
    'nouveau': 'Nouveau',
    'en_cours': 'En cours',
    'resolu': 'Résolu',
    'en_attente': 'En attente',
  };

  static const prioriteLabels = {
    'elevee': 'Élevée',
    'moyenne': 'Moyenne',
    'faible': 'Faible',
  };

  String get typeLabel => typeLabels[type] ?? type;
  String get statutLabel => statutLabels[statut] ?? statut;
  String get prioriteLabel => prioriteLabels[priorite] ?? priorite;

  String get ilYA {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return "à l'instant";
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours} h';
    return 'il y a ${diff.inDays} j';
  }
}

class ReportCreatePayload {
  final String type;
  final String description;
  final String zone;
  final String adresse;
  final double? latitude;
  final double? longitude;
  final int? segment;

  ReportCreatePayload({
    required this.type,
    this.description = '',
    required this.zone,
    this.adresse = '',
    this.latitude,
    this.longitude,
    this.segment,
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        'description': description,
        'zone': zone,
        'adresse': adresse,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (segment != null) 'segment': segment,
      };
}
