import '../models/user.dart';
import 'api_client.dart';

/// Écran Profil : lieux enregistrés, préférences, zones à surveiller.
class ProfileService {
  final _api = ApiClient.instance;

  Future<List<SavedPlace>> getLieux() async {
    final data = await _api.get('/api/auth/me/lieux/');
    final results = (data is Map && data.containsKey('results')) ? data['results'] : data;
    return (results as List).map((e) => SavedPlace.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<SavedPlace> addLieu(SavedPlace lieu) async {
    final data = await _api.post('/api/auth/me/lieux/', body: lieu.toJson());
    return SavedPlace.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteLieu(int id) => _api.delete('/api/auth/me/lieux/$id/');

  Future<UserPreferences> getPreferences() async {
    final data = await _api.get('/api/auth/me/preferences/');
    return UserPreferences.fromJson(data as Map<String, dynamic>);
  }

  Future<UserPreferences> updatePreferences(UserPreferences prefs) async {
    final data = await _api.patch('/api/auth/me/preferences/', body: prefs.toJson());
    return UserPreferences.fromJson(data as Map<String, dynamic>);
  }

  Future<List<ZoneSurveillee>> getZonesSurveillees() async {
    final data = await _api.get('/api/auth/me/zones-surveillees/');
    final results = (data is Map && data.containsKey('results')) ? data['results'] : data;
    return (results as List).map((e) => ZoneSurveillee.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> addZoneSurveillee(String zone) =>
      _api.post('/api/auth/me/zones-surveillees/', body: {'zone': zone});

  Future<void> deleteZoneSurveillee(int id) => _api.delete('/api/auth/me/zones-surveillees/$id/');
}
