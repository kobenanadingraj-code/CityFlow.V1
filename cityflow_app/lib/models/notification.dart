class AppNotification {
  final int id;
  final String type; // alerte | signalement | systeme
  final String titre;
  final String message;
  final bool lu;
  final String lienObjet;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.type,
    required this.titre,
    required this.message,
    required this.lu,
    required this.lienObjet,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['id'] as int,
        type: json['type'] as String,
        titre: json['titre'] as String,
        message: json['message'] as String,
        lu: json['lu'] as bool? ?? false,
        lienObjet: json['lien_objet'] as String? ?? '',
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
