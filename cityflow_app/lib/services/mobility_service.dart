import '../models/mobility.dart';
import 'api_client.dart';

/// Écran Carte — prévisions par créneau + zones à risque.
class MobilityService {
  final _api = ApiClient.instance;

  Future<CartePrevisions> previsions({String? zone}) async {
    final data = await _api.get('/api/previsions/', query: {if (zone != null) 'zone': zone});
    return CartePrevisions.fromJson(data as Map<String, dynamic>);
  }

  Future<List<CommuneStats>> communes() async {
    final data = await _api.get('/api/communes/', auth: false);
    return (data as List).map((e) => CommuneStats.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> predictSegment(int segmentId) async {
    final data = await _api.get('/api/segments/$segmentId/predict/');
    return data as Map<String, dynamic>;
  }
}
