import 'dart:typed_data';

import '../models/report.dart';
import 'api_client.dart';

/// Écrans Alertes (mobile) et Gestion des signalements (dashboard web).
class ReportsService {
  final _api = ApiClient.instance;

  Future<List<Report>> list({
    String? type,
    String? statut,
    String? priorite,
    String? zone,
    String? q,
    String? dateDebut,
    String? dateFin,
    int page = 1,
    int pageSize = 10,
  }) async {
    final data = await _api.get('/api/reports/', query: {
      if (type != null && type != 'toutes') 'type': type,
      if (statut != null) 'statut': statut,
      if (priorite != null) 'priorite': priorite,
      if (zone != null) 'zone': zone,
      if (q != null) 'q': q,
      if (dateDebut != null) 'date_debut': dateDebut,
      if (dateFin != null) 'date_fin': dateFin,
      'page': page,
      'page_size': pageSize,
    });
    final results = (data is Map && data.containsKey('results')) ? data['results'] : data;
    return (results as List).map((e) => Report.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<int> count({String? type, String? statut}) async {
    final data = await _api.get('/api/reports/', query: {
      if (type != null && type != 'toutes') 'type': type,
      if (statut != null) 'statut': statut,
      'page_size': 1,
    });
    return data is Map && data.containsKey('count') ? data['count'] as int : 0;
  }

  /// Bouton 'Envoyer un signalement'. Si une photo est fournie (bytes issus
  /// de image_picker), l'envoi passe en multipart/form-data.
  Future<Report> create(ReportCreatePayload payload, {Uint8List? photoBytes, String? photoFileName}) async {
    if (photoBytes != null && photoFileName != null) {
      final fields = payload.toJson().map((k, v) => MapEntry(k, v.toString()));
      final data = await _api.postMultipart('/api/reports/', fields: fields, fileBytes: photoBytes, fileName: photoFileName);
      return Report.fromJson(data as Map<String, dynamic>);
    }
    final data = await _api.post('/api/reports/', body: payload.toJson());
    return Report.fromJson(data as Map<String, dynamic>);
  }

  Future<Report> detail(int id) async {
    final data = await _api.get('/api/reports/$id/');
    return Report.fromJson(data as Map<String, dynamic>);
  }

  /// Dashboard, colonne 'Actions' — autorité uniquement.
  Future<Report> updateStatutPriorite(int id, {String? statut, String? priorite}) async {
    final data = await _api.patch('/api/reports/$id/', body: {
      if (statut != null) 'statut': statut,
      if (priorite != null) 'priorite': priorite,
    });
    return Report.fromJson(data as Map<String, dynamic>);
  }

  Future<void> delete(int id) => _api.delete('/api/reports/$id/');
}
