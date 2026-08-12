class RoadSegment {
  final int id;
  final String nom;
  final double latitude;
  final double longitude;
  final String zone;
  final bool zoneInondable;

  RoadSegment({
    required this.id,
    required this.nom,
    required this.latitude,
    required this.longitude,
    required this.zone,
    required this.zoneInondable,
  });

  factory RoadSegment.fromJson(Map<String, dynamic> json) => RoadSegment(
        id: json['id'] as int,
        nom: json['nom'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        zone: json['zone'] as String,
        zoneInondable: json['zone_inondable'] as bool? ?? false,
      );
}

class CommuneStats {
  final String zone;
  final int nbSegments;
  final int scoreMoyen;
  final int scoreMax;
  final int nbCritiques;

  CommuneStats({
    required this.zone,
    required this.nbSegments,
    required this.scoreMoyen,
    required this.scoreMax,
    required this.nbCritiques,
  });

  factory CommuneStats.fromJson(Map<String, dynamic> json) => CommuneStats(
        zone: json['zone'] as String,
        nbSegments: json['nb_segments'] as int,
        scoreMoyen: json['score_moyen'] as int,
        scoreMax: json['score_max'] as int,
        nbCritiques: json['nb_critiques'] as int,
      );
}

class PeakHour {
  final String heure;
  final int scoreMoyen;
  final String niveau;

  PeakHour({required this.heure, required this.scoreMoyen, required this.niveau});

  factory PeakHour.fromJson(Map<String, dynamic> json) => PeakHour(
        heure: json['heure'] as String,
        scoreMoyen: json['score_moyen'] as int,
        niveau: json['niveau'] as String,
      );
}

class ZoneRisque {
  final String zone;
  final String creneau;
  final int scoreMoyen;
  final String niveau;

  ZoneRisque({
    required this.zone,
    required this.creneau,
    required this.scoreMoyen,
    required this.niveau,
  });

  factory ZoneRisque.fromJson(Map<String, dynamic> json) => ZoneRisque(
        zone: json['zone'] as String,
        creneau: json['creneau'] as String,
        scoreMoyen: json['score_moyen'] as int,
        niveau: json['niveau'] as String,
      );
}

class CartePrevisions {
  final List<PeakHour> heuresDePointe;
  final List<ZoneRisque> zonesARisque;
  final DateTime derniereMiseAJour;

  CartePrevisions({
    required this.heuresDePointe,
    required this.zonesARisque,
    required this.derniereMiseAJour,
  });

  factory CartePrevisions.fromJson(Map<String, dynamic> json) => CartePrevisions(
        heuresDePointe: (json['heures_de_pointe'] as List)
            .map((e) => PeakHour.fromJson(e as Map<String, dynamic>))
            .toList(),
        zonesARisque: (json['zones_a_risque'] as List)
            .map((e) => ZoneRisque.fromJson(e as Map<String, dynamic>))
            .toList(),
        derniereMiseAJour: DateTime.parse(json['derniere_mise_a_jour'] as String),
      );
}
