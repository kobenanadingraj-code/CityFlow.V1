import 'package:flutter/foundation.dart';
import '../models/user.dart';
import 'api_client.dart';

/// État d'authentification global de l'app — écran Bienvenue/Connexion,
/// Créer un compte, et Profil s'appuient dessus via Provider.
class AuthService extends ChangeNotifier {
  final _api = ApiClient.instance;

  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  Future<bool> tryAutoLogin() async {
    if (!await _api.isLoggedIn) return false;
    try {
      await refreshMe();
      return true;
    } catch (_) {
      await _api.clearTokens();
      return false;
    }
  }

  /// Écran Bienvenue — connexion par email OU téléphone.
  Future<void> login({required String identifiant, required String motDePasse}) async {
    final data = await _api.post(
      '/api/auth/login/',
      auth: false,
      body: {'identifiant': identifiant, 'password': motDePasse},
    );
    await _api.saveTokens(access: data['access'] as String, refresh: data['refresh'] as String);
    _currentUser = AppUser.fromJson(data['user'] as Map<String, dynamic>);
    notifyListeners();
  }

  /// Écran Créer un compte.
  Future<void> register({
    required String nomComplet,
    required String email,
    String? telephone,
    required String motDePasse,
  }) async {
    await _api.post(
      '/api/auth/register/',
      auth: false,
      body: {
        'nom_complet': nomComplet,
        'email': email,
        if (telephone != null && telephone.isNotEmpty) 'telephone': telephone,
        'password': motDePasse,
      },
    );
    // Inscription réussie → connexion automatique
    await login(identifiant: email, motDePasse: motDePasse);
  }

  Future<void> refreshMe() async {
    final data = await _api.get('/api/auth/me/');
    _currentUser = AppUser.fromJson(data as Map<String, dynamic>);
    notifyListeners();
  }

  Future<void> updateProfile(Map<String, dynamic> fields) async {
    final data = await _api.patch('/api/auth/me/', body: fields);
    _currentUser = AppUser.fromJson(data as Map<String, dynamic>);
    notifyListeners();
  }

  Future<void> logout() async {
    await _api.clearTokens();
    _currentUser = null;
    notifyListeners();
  }
}
