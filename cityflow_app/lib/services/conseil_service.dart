import '../models/itineraire.dart';
import 'api_client.dart';

/// Écrans Trajet (recherche libre) et Carte (itinéraires recommandés).
class ConseilService {
  final _api = ApiClient.instance;

  /// Lève ApiException(503) si OSRM n'est pas configuré côté backend.
  Future<Map<String, dynamic>> trajetLibre({
    required double origineLat,
    required double origineLng,
    required double destinationLat,
    required double destinationLng,
    String destinationLabel = 'Destination',
  }) async {
    final data = await _api.get('/api/conseil/trajet/', query: {
      'origine_lat': origineLat,
      'origine_lng': origineLng,
      'destination_lat': destinationLat,
      'destination_lng': destinationLng,
      'destination_label': destinationLabel,
    });
    final map = data as Map<String, dynamic>;
    return {
      'itineraires': (map['itineraires'] as List)
          .map((e) => ItineraireResult.fromJson(e as Map<String, dynamic>))
          .toList(),
      'conseil': map['conseil'] as String?,
    };
  }

  Future<List<ItineraireRecommande>> itinerairesRecommandes() async {
    final data = await _api.get('/api/conseil/itineraires-recommandes/');
    final list = (data as Map<String, dynamic>)['itineraires_recommandes'] as List;
    return list.map((e) => ItineraireRecommande.fromJson(e as Map<String, dynamic>)).toList();
  }
}
