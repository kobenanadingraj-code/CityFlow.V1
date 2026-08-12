class AppUser {
  final int id;
  final String nomComplet;
  final String email;
  final String? telephone;
  final String adresse;
  final String? avatar;
  final String role; // 'citoyen' | 'autorite'
  final String zone;

  AppUser({
    required this.id,
    required this.nomComplet,
    required this.email,
    this.telephone,
    this.adresse = '',
    this.avatar,
    required this.role,
    this.zone = '',
  });

  bool get isAutorite => role == 'autorite';

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as int,
        nomComplet: json['nom_complet'] as String? ?? '',
        email: json['email'] as String? ?? '',
        telephone: json['telephone'] as String?,
        adresse: json['adresse'] as String? ?? '',
        avatar: json['avatar'] as String?,
        role: json['role'] as String? ?? 'citoyen',
        zone: json['zone'] as String? ?? '',
      );
}

class SavedPlace {
  final int id;
  final String type; // maison | travail | favori | autre
  final String label;
  final String adresse;
  final double latitude;
  final double longitude;

  SavedPlace({
    required this.id,
    required this.type,
    required this.label,
    required this.adresse,
    required this.latitude,
    required this.longitude,
  });

  factory SavedPlace.fromJson(Map<String, dynamic> json) => SavedPlace(
        id: json['id'] as int,
        type: json['type'] as String,
        label: json['label'] as String? ?? '',
        adresse: json['adresse'] as String? ?? '',
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'type': type,
        'label': label,
        'adresse': adresse,
        'latitude': latitude,
        'longitude': longitude,
      };

  String get displayLabel {
    switch (type) {
      case 'maison':
        return 'Maison';
      case 'travail':
        return 'Travail';
      case 'favori':
        return label.isNotEmpty ? label : 'Favori';
      default:
        return label.isNotEmpty ? label : 'Autre';
    }
  }
}

class UserPreferences {
  final bool notificationsActives;
  final String modeTransport;
  final bool eviterZonesInondables;
  final bool eviterPeages;

  UserPreferences({
    required this.notificationsActives,
    required this.modeTransport,
    required this.eviterZonesInondables,
    required this.eviterPeages,
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) => UserPreferences(
        notificationsActives: json['notifications_actives'] as bool? ?? true,
        modeTransport: json['mode_transport'] as String? ?? 'voiture',
        eviterZonesInondables: json['eviter_zones_inondables'] as bool? ?? true,
        eviterPeages: json['eviter_peages'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'notifications_actives': notificationsActives,
        'mode_transport': modeTransport,
        'eviter_zones_inondables': eviterZonesInondables,
        'eviter_peages': eviterPeages,
      };
}

class ZoneSurveillee {
  final int id;
  final String zone;

  ZoneSurveillee({required this.id, required this.zone});

  factory ZoneSurveillee.fromJson(Map<String, dynamic> json) =>
      ZoneSurveillee(id: json['id'] as int, zone: json['zone'] as String);
}
