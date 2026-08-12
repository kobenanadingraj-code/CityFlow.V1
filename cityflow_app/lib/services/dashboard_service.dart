import '../models/dashboard.dart';
import 'api_client.dart';

/// Écran Tableau de bord (dashboard web, autorité uniquement).
class DashboardService {
  final _api = ApiClient.instance;

  Future<DashboardStats> stats() async {
    final data = await _api.get('/api/dashboard/stats/');
    return DashboardStats.fromJson(data as Map<String, dynamic>);
  }

  Future<List<IncidentCarte>> incidentsCarte() async {
    final data = await _api.get('/api/dashboard/incidents-carte/');
    return (data as List).map((e) => IncidentCarte.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<RepartitionParType> repartitionParType() async {
    final data = await _api.get('/api/dashboard/repartition-par-type/');
    return RepartitionParType.fromJson(data as Map<String, dynamic>);
  }

  Future<List<ActivityLogEntry>> activiteRecente({int limit = 10}) async {
    final data = await _api.get('/api/dashboard/activite-recente/', query: {'limit': limit});
    return (data as List).map((e) => ActivityLogEntry.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Map<String, dynamic>>> criticalZones() async {
    final data = await _api.get('/api/dashboard/critical-zones/');
    return (data as List).cast<Map<String, dynamic>>();
  }
}
