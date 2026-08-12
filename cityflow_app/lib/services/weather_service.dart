import '../models/mobility.dart';
import '../models/weather.dart';
import 'api_client.dart';

/// Écran Accueil — carte 'Météo : 28°C, Ensoleillé' — et écran Alertes du
/// dashboard web (segments inondables actuellement sous alerte météo).
class WeatherService {
  final _api = ApiClient.instance;

  Future<WeatherEvent?> current({String? zone}) async {
    final data = await _api.get('/api/weather/current/', query: {if (zone != null) 'zone': zone}, auth: false);
    if (data is List && data.isEmpty) return null;
    if (data is Map) return WeatherEvent.fromJson(data as Map<String, dynamic>);
    return null;
  }

  /// Segments zone_inondable dont la zone a une alerte météo active (non 'normal').
  Future<List<RoadSegment>> alerts() async {
    final data = await _api.get('/api/weather/alerts/', auth: false);
    return (data as List).map((e) => RoadSegment.fromJson(e as Map<String, dynamic>)).toList();
  }
}
