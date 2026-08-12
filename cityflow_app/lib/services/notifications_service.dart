import '../models/notification.dart';
import 'api_client.dart';

/// Cloche de notifications — Accueil et Profil.
class NotificationsService {
  final _api = ApiClient.instance;

  Future<List<AppNotification>> list({bool? lu}) async {
    final data = await _api.get('/api/notifications/', query: {if (lu != null) 'lu': lu});
    final results = (data is Map && data.containsKey('results')) ? data['results'] : data;
    return (results as List).map((e) => AppNotification.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<int> unreadCount() async {
    final data = await _api.get('/api/notifications/non-lues/');
    return (data as Map<String, dynamic>)['non_lues'] as int;
  }

  Future<void> markRead(int id) => _api.patch('/api/notifications/$id/lu/', body: {});

  Future<void> markAllRead() => _api.post('/api/notifications/marquer-toutes-lues/');
}
