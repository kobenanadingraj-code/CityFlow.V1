import '../models/export_job.dart';
import 'api_client.dart';

/// Écran Export des données (dashboard web, autorité uniquement).
class ExportsService {
  final _api = ApiClient.instance;

  Future<List<ExportJob>> list() async {
    final data = await _api.get('/api/exports/');
    final results = (data is Map && data.containsKey('results')) ? data['results'] : data;
    return (results as List).map((e) => ExportJob.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ExportJob> create({
    required String typeDonnees,
    required DateTime periodeDebut,
    required DateTime periodeFin,
    Map<String, dynamic> filtres = const {},
    required String format,
    String nom = '',
  }) async {
    final data = await _api.post('/api/exports/', body: {
      'nom': nom,
      'type_donnees': typeDonnees,
      'periode_debut': periodeDebut.toIso8601String().split('T').first,
      'periode_fin': periodeFin.toIso8601String().split('T').first,
      'filtres': filtres,
      'format': format,
    });
    return ExportJob.fromJson(data as Map<String, dynamic>);
  }
}
