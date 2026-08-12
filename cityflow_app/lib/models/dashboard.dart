class KpiValue {
  final int valeur;
  final double? variationPct;

  KpiValue({required this.valeur, this.variationPct});

  factory KpiValue.fromJson(Map<String, dynamic> json) => KpiValue(
        valeur: json['valeur'] as int,
        variationPct: (json['variation_pct'] as num?)?.toDouble(),
      );
}

class DashboardStats {
  final KpiValue signalementsAujourdhui;
  final KpiValue incidentsActifs;
  final KpiValue zonesARisque;
  final KpiValue utilisateursActifs;

  DashboardStats({
    required this.signalementsAujourdhui,
    required this.incidentsActifs,
    required this.zonesARisque,
    required this.utilisateursActifs,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) => DashboardStats(
        signalementsAujourdhui: KpiValue.fromJson(json['signalements_aujourdhui']),
        incidentsActifs: KpiValue.fromJson(json['incidents_actifs']),
        zonesARisque: KpiValue.fromJson(json['zones_a_risque']),
        utilisateursActifs: KpiValue.fromJson(json['utilisateurs_actifs']),
      );
}

class ActivityLogEntry {
  final String type;
  final String description;
  final String? user;
  final DateTime createdAt;

  ActivityLogEntry({
    required this.type,
    required this.description,
    this.user,
    required this.createdAt,
  });

  factory ActivityLogEntry.fromJson(Map<String, dynamic> json) => ActivityLogEntry(
        type: json['type'] as String,
        description: json['description'] as String,
        user: json['user'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  String get ilYA {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return "à l'instant";
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours} h';
    return 'il y a ${diff.inDays} j';
  }
}

class RepartitionItem {
  final String type;
  final int total;
  final double pourcentage;

  RepartitionItem({required this.type, required this.total, required this.pourcentage});

  factory RepartitionItem.fromJson(Map<String, dynamic> json) => RepartitionItem(
        type: json['type'] as String,
        total: json['total'] as int,
        pourcentage: (json['pourcentage'] as num).toDouble(),
      );
}

class RepartitionParType {
  final int total;
  final List<RepartitionItem> repartition;

  RepartitionParType({required this.total, required this.repartition});

  factory RepartitionParType.fromJson(Map<String, dynamic> json) => RepartitionParType(
        total: json['total'] as int,
        repartition: (json['repartition'] as List)
            .map((e) => RepartitionItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class IncidentCarte {
  final int id;
  final String type;
  final double latitude;
  final double longitude;
  final String zone;

  IncidentCarte({
    required this.id,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.zone,
  });

  factory IncidentCarte.fromJson(Map<String, dynamic> json) => IncidentCarte(
        id: json['id'] as int,
        type: json['type'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        zone: json['zone'] as String,
      );
}
