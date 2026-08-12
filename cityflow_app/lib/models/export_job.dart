class ExportJob {
  final int id;
  final String nom;
  final String typeDonnees; // signalements | utilisateurs | alertes | statistiques
  final DateTime periodeDebut;
  final DateTime periodeFin;
  final Map<String, dynamic> filtres;
  final String format; // csv | xlsx | pdf
  final String statut; // en_cours | termine | echec
  final int? tailleOctets;
  final String demandeParNom;
  final String? fichierUrl;
  final DateTime createdAt;

  ExportJob({
    required this.id,
    required this.nom,
    required this.typeDonnees,
    required this.periodeDebut,
    required this.periodeFin,
    required this.filtres,
    required this.format,
    required this.statut,
    this.tailleOctets,
    required this.demandeParNom,
    this.fichierUrl,
    required this.createdAt,
  });

  factory ExportJob.fromJson(Map<String, dynamic> json) => ExportJob(
        id: json['id'] as int,
        nom: json['nom'] as String? ?? '',
        typeDonnees: json['type_donnees'] as String,
        periodeDebut: DateTime.parse(json['periode_debut'] as String),
        periodeFin: DateTime.parse(json['periode_fin'] as String),
        filtres: (json['filtres'] as Map?)?.cast<String, dynamic>() ?? {},
        format: json['format'] as String,
        statut: json['statut'] as String,
        tailleOctets: json['taille_octets'] as int?,
        demandeParNom: json['demande_par_nom'] as String? ?? '',
        fichierUrl: json['fichier_url'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  String get tailleLisible {
    if (tailleOctets == null) return '—';
    final ko = tailleOctets! / 1024;
    if (ko < 1024) return '${ko.toStringAsFixed(0)} Ko';
    return '${(ko / 1024).toStringAsFixed(2)} Mo';
  }
}
